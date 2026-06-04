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
      // 提交后可选自动切换到反馈记录Tab
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
      buttons: [{ text: '关闭', color: '#FFA6C1' }]
    });
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_backward'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })
        Text('意见反馈')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(60)
      .padding({ left: 15, right: 15 })
      .backgroundColor('#FFD6E0')

      // Tab切换栏
      Row() {
        this.TabItem('反馈问题', 0)
        this.TabItem('反馈记录', 1)
      }
      .width('100%')
      .height(50)
      .backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.SpaceAround)

      // 内容区域
      if (this.currentTab === 0) {
        this.FeedbackForm()
      } else {
        this.FeedbackHistory()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFF5F7')
  }

  @Builder
  TabItem(title: string, index: number) {
    Text(title)
      .fontSize(16)
      .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.currentTab === index ? '#FFA6C1' : '#999999')
      .padding({ bottom: 10 })
      .border({
        width: { bottom: 2 },
        color: this.currentTab === index ? '#FFA6C1' : 'transparent'
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
          Text('反馈问题')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .margin({ bottom: 12 })
            .alignSelf(ItemAlign.Start)

          TextArea({ placeholder: '请详细描述您的问题或建议...', text: this.feedbackContent })
            .placeholderColor('#CCCCCC')
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .padding(12)
            .height(150)
            .maxLength(500)
            .onChange((value: string) => {
              this.feedbackContent = value;
            })

          TextInput({ placeholder: '联系方式（手机号/邮箱，选填）', text: this.contact })
            .placeholderColor('#CCCCCC')
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .padding(12)
            .margin({ top: 12 })
            .onChange((value: string) => {
              this.contact = value;
            })

          Button('提交反馈')
            .width('100%')
            .height(44)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#FFA6C1')
            .borderRadius(22)
            .margin({ top: 20 })
            .enabled(!this.isSubmitting)
            .onClick(() => {
              this.submitFeedback();
            })
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .margin({ top: 16, left: 16, right: 16, bottom: 20 })
      }
      .padding({ bottom: 20 })
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
            Text('反馈记录')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
            Text(`${this.feedbackList.length}`)
              .fontSize(14)
              .fontColor('#FFA6C1')
              .margin({ left: 8 })
          }
          .width('100%')
          .margin({ bottom: 12 })

          if (this.feedbackList.length === 0) {
            Column() {
              Image($r('app.media.ic_user_unlogin'))
                .width(60)
                .height(60)
                .opacity(0.4)
                .margin({ top: 30 })
              Text('暂无反馈记录')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 12, bottom: 30 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          } else {
            List() {
              ForEach(this.feedbackList, (item: Feedback) => {
                ListItem() {
                  Column() {
                    Row() {
                      Column() {
                        Text(this.getShortContent(item.content))
                          .fontSize(15)
                          .fontColor('#333333')
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .width('100%')
                        Text(this.formatTime(item.createTime))
                          .fontSize(12)
                          .fontColor('#999999')
                          .margin({ top: 8 })
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)
                      Image($r('app.media.ic_backward'))
                        .width(16)
                        .height(16)
                        .fillColor('#CCCCCC')
                        .rotate({ angle: 180 })
                        .margin({ left: 12 })
                    }
                    .width('100%')
                    .padding(12)
                  }
                  .width('100%')
                  .backgroundColor('#F9F9F9')
                  .borderRadius(12)
                  .margin({ bottom: 8 })
                  .onClick(() => {
                    this.showFeedbackDetail(item);
                  })
                }
              }, (item: Feedback) => item.id)
            }
            .width('100%')
            .height('auto')
            .divider({ strokeWidth: 0 })
            .scrollBar(BarState.Off)
          }
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .margin({ top: 16, left: 16, right: 16, bottom: 20 })
      }
      .padding({ bottom: 20 })
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