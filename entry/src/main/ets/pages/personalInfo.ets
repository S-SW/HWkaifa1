// pages/PersonalInfo.ets
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import ApiService from '../network/ApiService';
import { User } from '../model/Entities';

@Entry
@Component
struct PersonalInfo {
  @State userInfo: User | null = null;
  @State nickname: string = '未设置';
  @State username: string = '';
  @State phone: string = '未绑定';
  @State displayName: string = '用户';
  @State isLoading: boolean = false;

  async aboutToAppear() {
    await this.loadUserInfo();
  }

  async onPageShow() {
    await this.loadUserInfo();
  }

  async loadUserInfo() {
    this.isLoading = true;
    try {
      const info = await ApiService.getUserInfo();
      this.userInfo = info;
      this.updateDisplayValues(info);
    } catch (e) {
      promptAction.showToast({ message: '获取用户信息失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  updateDisplayValues(info: User | null) {
    if (info) {
      this.nickname = info.nickname || info.username || '未设置';
      this.username = info.username || '';
      this.phone = info.phone || '未绑定';
      this.displayName = info.nickname || info.username || '用户';
    } else {
      this.nickname = '未设置';
      this.username = '';
      this.phone = '未绑定';
      this.displayName = '用户';
    }
  }

  build() {
    Column() {
      // 顶部导航栏 - 改为深蓝底白字，并修正绝对居中
      Row() {
        Image($r('app.media.ic_backward'))
          .width(22)
          .height(22)
          .onClick(() => {
            router.back();
          })

        Text('个人信息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF') // 文字改为白色
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 22 }) // 抵消返回键宽度以居中
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#409EFF') // 改为主题深蓝色

      if (this.isLoading) {
        Blank()
        LoadingProgress()
          .width(40)
          .height(40)
          .color('#409EFF') // 加载动画改为主题蓝色
        Blank()
      } else {
        Scroll() {
          Column() {
            // 头像与基本信息卡片
            Column() {
              Row() {
                Image(this.userInfo?.avatarUrl || $r('app.media.ic_user_default'))
                  .width(90)
                  .height(90)
                  .borderRadius(45)
                  .backgroundColor('#F5F7FA')
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding({ top: 24, bottom: 16 })

              Text(this.displayName)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .margin({ bottom: 6 })

              Text('ID: ' + (this.userInfo?.userId || ''))
                .fontSize(13)
                .fontColor('#999999')
            }
            .width('calc(100% - 32vp)') // 左右留出间距，拒绝死板贴边
            .padding({ bottom: 20 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .shadow({ radius: 8, color: '#08000000', offsetX: 0, offsetY: 4 }) // 融入精致微阴影
            .margin({ top: 16 }) // 控制顶部距离

            // 详细账号信息卡片
            Column() {
              this.InfoItem('昵称', this.nickname)
              Divider().width('92%').color('#EDF2F7')
              this.InfoItem('用户名', this.username)
              Divider().width('92%').color('#EDF2F7')
              this.InfoItem('手机号', this.phone)
            }
            .width('calc(100% - 32vp)') // 保持间距一致
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .shadow({ radius: 8, color: '#08000000', offsetX: 0, offsetY: 4 })
            .margin({ top: 14, bottom: 16 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .align(Alignment.Top)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E6F4F8') // 改为与整体 App 匹配的舒适清爽浅蓝色底色
  }

  @Builder
  InfoItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#666666')
        .width(80)

      Text(value)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
  }
}