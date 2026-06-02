import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import hilog from '@ohos.hilog';
import ApiService from '../network/ApiService';
import AppStorage from '../utils/AppStorage';
import AuthGuard from '../utils/AuthGuard';

const TAG = 'Login';

@Entry
@Component
struct Login {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;

  build() {
    Column() {
      Column() {
        Image($r('app.media.icon'))
          .width(80)
          .height(80)
          .margin({ top: 60 })

        Text('食堂订餐')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ top: 15 })
      }
      .width('100%')
      .height(220)
      .backgroundColor('#FF6B35')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text('用户名登录')
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ top: 30, bottom: 30 })

        TextInput({ placeholder: '请输入用户名' })
          .width('90%')
          .height(50)
          .fontSize(16)
          .backgroundColor('#F5F5F5')
          .borderRadius(10)
          .margin({ bottom: 15 })
          .onChange((value: string) => {
            this.username = value;
          })

        TextInput({ placeholder: '请输入密码' })
          .width('90%')
          .height(50)
          .fontSize(16)
          .type(InputType.Password)
          .backgroundColor('#F5F5F5')
          .borderRadius(10)
          .margin({ bottom: 25 })
          .onChange((value: string) => {
            this.password = value;
          })

        Button(this.isLoading ? '登录中...' : '登录')
          .width('90%')
          .height(50)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#FF6B35')
          .borderRadius(25)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.doLogin();
          })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  async doLogin() {
    hilog.info(0x0000, TAG, '开始登录验证');
    if (!this.username || this.username.length < 3) {
      promptAction.showToast({ message: '用户名至少3位', duration: 2000 });
      return;
    }

    if (!this.password || this.password.length < 6) {
      promptAction.showToast({ message: '密码至少6位', duration: 2000 });
      return;
    }

    hilog.info(0x0000, TAG, '验证通过，准备发送登录请求');
    this.isLoading = true;

    try {
      let user = await ApiService.login(this.username, this.password);
      hilog.info(0x0000, TAG, '登录请求完成，用户信息: %{public}s', JSON.stringify(user));
      if (user && user.userId) {
        await AppStorage.setUserInfo(user);
        await AppStorage.setToken(user.token || '');
        promptAction.showToast({ message: '登录成功', duration: 2000 });

        setTimeout(() => {
          AuthGuard.navigateAfterLogin();
        }, 500);
      } else {
        promptAction.showToast({ message: '登录失败，请检查账号密码', duration: 2000 });
      }
    } catch (e) {
      hilog.error(0x0000, TAG, '登录异常: %{public}s', JSON.stringify(e));
      promptAction.showToast({ message: '登录失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }
}