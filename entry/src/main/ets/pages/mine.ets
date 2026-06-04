import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import AppStorage from '../utils/AppStorage';
import AuthGuard from '../utils/AuthGuard';
import { User } from '../model/Entities';

@Entry
@Component
struct Mine {
  @State userInfo: User | null = null;
  @State isLoggedIn: boolean = false;

  async aboutToAppear() {
    await this.checkLoginStatus();
  }

  async onPageShow() {
    await this.checkLoginStatus();
  }

  async checkLoginStatus() {
    this.isLoggedIn = await AuthGuard.isLoggedIn();
    if (this.isLoggedIn) {
      this.userInfo = await AppStorage.getUserInfo();
    } else {
      this.userInfo = null;
    }
  }

  build() {
    Column() {
      if (this.isLoggedIn) {
        this.LoggedInView()
      } else {
        this.NotLoggedInView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffc2faf5')
  }

  @Builder
  NotLoggedInView() {
    Column() {
      Row() {
        Image($r('app.media.ic_backward'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.pushUrl({ url: 'pages/home' });
          })

        Text('我的')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(60)
      .padding({ left: 15, right: 15 })
      .backgroundColor('#FFFFFF')

      Column() {
        Image($r('app.media.ic_user_unlogin'))
          .width(80)
          .height(80)
          .opacity(0.5)

        Text('未登录')
          .fontSize(18)
          .fontColor('#666666')
          .margin({ top: 15 })

        Button('登录')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF6B35')
          .borderRadius(25)
          .padding({ left: 50, right: 50, top: 12, bottom: 12 })
          .margin({ top: 30 })
          .onClick(() => {
            AuthGuard.setRedirectUrl('pages/mine');
            router.pushUrl({ url: 'pages/login' });
          })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  LoggedInView() {
    Column() {
      Row() {
        Image($r('app.media.ic_backward'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.pushUrl({ url: 'pages/home' });
          })

        Text('我的')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(60)
      .padding({ left: 15, right: 15 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          Column() {
            Row() {
              Image(this.userInfo?.avatarUrl || $r('app.media.ic_user_default'))
                .width(70)
                .height(70)
                .borderRadius(35)
                .backgroundColor('#F5F5F5')
                .onClick(() => {
                  router.pushUrl({ url: 'pages/personalInfo' });
                })

              Column() {
                Text(this.userInfo?.nickname || this.userInfo?.username || '用户')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')

                Text('用户名: ' + (this.userInfo?.username || ''))
                  .fontSize(14)
                  .fontColor('#999999')
                  .margin({ top: 5 })
              }
              .margin({ left: 15 })
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Image($r('app.media.ic_backward'))
                .width(20)
                .height(20)
                .fillColor('#999999')
                .rotate({ angle: 180 })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/personalInfo' });
                })
            }
            .width('100%')
            .padding(20)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          Column() {
            this.MenuItem('我的订单', $r('app.media.ic_order'), () => {
              router.pushUrl({ url: 'pages/order' });
            })

            Divider().width('90%').margin({ left: 50 })

            this.MenuItem('收货地址', $r('app.media.ic_my'), () => {
              router.pushUrl({ url: 'pages/address' });
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 10 })

          Column() {
            this.MenuItem('个人信息', $r('app.media.ic_my'), () => {
              router.pushUrl({ url: 'pages/personalInfo' });
            })

            Divider().width('90%').margin({ left: 50 })

            this.MenuItem('关于我们', $r('app.media.ic_my'), () => {
              promptAction.showToast({ message: '食堂订餐 v1.0.0', duration: 2000 });
            })

            Divider().width('90%').margin({ left: 50 })

            this.MenuItem('注销账号', $r('app.media.ic_my'), () => {
              this.showLogoutDialog();
            })

            Divider().width('90%').margin({ left: 50 })

            this.MenuItem('退出登录', $r('app.media.ic_my'), () => {
              this.showLogoutDialog();
            })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 10 })
        }
        .padding({ bottom: 20 })
      }
      .align(Alignment.Top)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MenuItem(title: string, icon: Resource, onClick: () => void) {
    Row() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor('#FF6B35')

      Text(title)
        .fontSize(16)
        .fontColor('#333333')
        .margin({ left: 15 })

      Image($r('app.media.ic_backward'))
        .width(16)
        .height(16)
        .fillColor('#CCCCCC')
        .rotate({ angle: 180 })
    }
    .width('100%')
    .padding(15)
    .onClick(onClick)
  }

  async showLogoutDialog() {
    try {
      const result = await promptAction.showDialog({
        title: '提示',
        message: '确定要退出登录吗？',
        buttons: [
          { text: '取消', color: '#999999' },
          { text: '确定', color: '#FF6B35' }
        ]
      });
      if (result.index === 1) {
        await this.logout();
      }
    } catch (e) {
    }
  }

  async logout() {
    await AppStorage.clearUserInfo();
    promptAction.showToast({ message: '已退出登录', duration: 2000 });
    setTimeout(() => {
      router.replaceUrl({ url: 'pages/home' });
    }, 500);
  }
}