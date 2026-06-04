// pages/feedback.ets
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { User, Feedback } from '../model/Entities';
import AppStorage from '../utils/AppStorage';
import FeedbackStorage from '../utils/FeedbackStorage';

@Entry
@Component
struct FeedbackPage {
  @State userInfo: User | null = null;
  @State currentTab: number = 0; // 0: 反馈问题, 1: 反馈记录
  @State feedbackContent: string = '';
  @State contact: string = '';
  @State feedbackList: Feedback[] = [];
  @State isSubmitting: boolean = false;
  private storage = FeedbackStorage;

  async aboutToAppear() {
    this.userInfo = await AppStorage.getUserInfo();
    if (!this.userInfo) {
      promptAction.showToast({ message: '请先登录', duration: 2000 });
      setTimeout(() => {
        router.back();
      }, 1500);
      return;
    }
    await this.storage.init(getContext(this));
    await this.loadFeedbacks();
  }

  async loadFeedbacks() {
    if (!this.userInfo) return;
    const userId = this.userInfo.userId;
    this.feedbackList = await this.storage.getFeedbacks(userId);
  }

  async submitFeedback() {
    if (!this.userInfo) {
      promptAction.showToast({ message: '用户信息异常', duration: 2000 });
      return;
    }
    if (!this.feedbackContent.trim()) {
      promptAction.showToast({ message: '请填写反馈内容', duration: 2000 });
      return;
    }
    if (this.isSubmitting) return;
    this.isSubmitting = true;

    try {
      const userId = this.userInfo.userId;
      const newFeedback = new Feedback();
      newFeedback.id = Date.now().toString();
      newFeedback.userId = userId;
      newFeedback.content = this.feedbackContent.trim();
      newFeedback.contact = this.contact.trim() || '未填写';
      newFeedback.createTime = Date.now();
      newFeedback.status = '待处理';

      await this.storage.addFeedback(newFeedback);
      await this.loadFeedbacks();
      this.feedbackContent = '';
      this.contact = '';
      promptAction.showToast({ message: '反馈提交成功，感谢您的建议！', duration: 2000 });
      this.currentTab = 1;
    } catch (error) {
      console.error('提交反馈失败', error);
      promptAction.showToast({ message: '提交失败，请稍后重试', duration: 2000 });
    } finally {
      this.isSubmitting = false;
    }
  }

  showFeedbackDetail(feedback: Feedback) {
    promptAction.showDialog({
      title: '反馈详情',
      message: `内容：${feedback.content}\n联系方式：${feedback.contact}\n时间：${new Date(feedback.createTime).toLocaleString()}\n状态：${feedback.status || '待处理'}`,
      buttons: [{ text: '关闭', color: '#409EFF' }]
    });
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_backward'))
          .width(22)
          .height(22)
          .onClick(() => {
            router.back();
          })
        Text('意见反馈')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 22 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#409EFF')

      // Tab切换栏
      Row() {
        this.TabItem('反馈问题', 0)
        this.TabItem('反馈记录', 1)
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.SpaceAround)
      .shadow({ radius: 4, color: '#10000000', offsetX: 0, offsetY: 2 })

      // 内容区域
      if (this.currentTab === 0) {
        this.FeedbackForm()
      } else {
        this.FeedbackHistory()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E6F4F8')
  }

  @Builder
  TabItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(15)
        .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTab === index ? '#409EFF' : '#666666')
        .padding({ bottom: 8 })
    }
    .border({
      width: { bottom: 3 },
      color: this.currentTab === index ? '#409EFF' : 'transparent'
    })
    .onClick(() => {
      this.currentTab = index;
    })
  }

  @Builder
  FeedbackForm() {
    Scroll() {
      Column() {
        Column() {
          Text('您的宝宝贵意见')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ bottom: 16 })
            .alignSelf(ItemAlign.Start)

          TextArea({ placeholder: '请详细描述您的问题或建议...', text: this.feedbackContent })
            .placeholderColor('#999999')
            .backgroundColor('#F7F8FA')
            .borderRadius(8)
            .padding(12)
            .height(160)
            .maxLength(500)
            .onChange((value: string) => {
              this.feedbackContent = value;
            })

          TextInput({ placeholder: '联系方式（手机号/邮箱，选填）', text: this.contact })
            .placeholderColor('#999999')
            .backgroundColor('#F7F8FA')
            .borderRadius(8)
            .padding(12)
            .margin({ top: 16 })
            .onChange((value: string) => {
              this.contact = value;
            })

          Button('提交反馈')
            .width('100%')
            .height(46)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .backgroundColor('#409EFF')
            .borderRadius(23)
            .margin({ top: 28 })
            .enabled(!this.isSubmitting)
            .onClick(() => {
              this.submitFeedback();
            })
        }
        .width('calc(100% - 32vp)')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 8, color: '#08000000', offsetX: 0, offsetY: 4 })
        .margin({ top: 0, bottom: 16 }) // 核心优化：去掉顶部的 margin，改成 0
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  @Builder
  FeedbackHistory() {
    Scroll() {
      Column() {
        Column() {
          Row() {
            Text('全部反馈')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Text(`${this.feedbackList.length}`)
              .fontSize(13)
              .fontColor('#FFFFFF')
              .backgroundColor('#409EFF')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(10)
              .margin({ left: 8 })
          }
          .width('100%')
          .margin({ bottom: 16 })

          if (this.feedbackList.length === 0) {
            Column() {
              Image($r('app.media.ic_user_unlogin'))
                .width(60)
                .height(60)
                .opacity(0.2)
                .margin({ top: 40 })
              Text('暂无反馈记录')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 12, bottom: 40 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          } else {
            List() {
              ForEach(this.feedbackList, (item: Feedback) => {
                ListItem() {
                  Row() {
                    Column() {
                      Text(this.getShortContent(item.content))
                        .fontSize(14)
                        .fontColor('#333333')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                        .lineHeight(20)

                      Row() {
                        Text(this.formatTime(item.createTime))
                          .fontSize(12)
                          .fontColor('#999999')

                        Blank()

                        Text(item.status || '待处理')
                          .fontSize(12)
                          .fontColor(item.status === '已处理' ? '#67C23A' : '#409EFF')
                      }
                      .width('100%')
                      .margin({ top: 10 })
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    Image($r('app.media.ic_backward'))
                      .width(14)
                      .height(14)
                      .fillColor('#999999')
                      .rotate({ angle: 180 })
                      .margin({ left: 12 })
                  }
                  .width('100%')
                  .padding(14)
                  .backgroundColor('#F8FAFC')
                  .borderRadius(8)
                  .margin({ bottom: 10 })
                  .onClick(() => {
                    this.showFeedbackDetail(item);
                  })
                }
              }, (item: Feedback) => item.id)
            }
            .width('100%')
            .height('auto')
          }
        }
        .width('calc(100% - 32vp)')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 8, color: '#08000000', offsetX: 0, offsetY: 4 })
        .margin({ top: 0, bottom: 16 }) // 历史记录的卡片顶部留白也同步去掉了
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  private getShortContent(content: string): string {
    if (content.length > 40) {
      return content.substring(0, 40) + '...';
    }
    return content;
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    if (diff < 24 * 3600 * 1000) {
      return `今天 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    } else if (diff < 48 * 3600 * 1000) {
      return '昨天';
    } else {
      return `${date.getMonth() + 1}/${date.getDate()}`;
    }
  }
}