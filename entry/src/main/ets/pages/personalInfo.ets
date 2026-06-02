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
      Row() {
        Image($r('app.media.ic_backward'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })

        Text('个人信息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('')
          .width(24)
      }
      .width('100%')
      .height(60)
      .padding({ left: 15, right: 15 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Blank()
        LoadingProgress()
          .width(40)
          .height(40)
      } else {
        Scroll() {
          Column() {
            Column() {
              Row() {
                Image(this.userInfo?.avatarUrl || $r('app.media.ic_user_default'))
                  .width(100)
                  .height(100)
                  .borderRadius(50)
                  .backgroundColor('#F5F5F5')
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding({ top: 30, bottom: 20 })

              Text(this.displayName)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .margin({ bottom: 5 })

              Text('ID: ' + (this.userInfo?.userId || ''))
                .fontSize(14)
                .fontColor('#999999')
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .margin({ top: 10 })

            Column() {
              this.InfoItem('昵称', this.nickname)
              Divider().width('90%').margin({ left: 50 })
              this.InfoItem('用户名', this.username)
              Divider().width('90%').margin({ left: 50 })
              this.InfoItem('手机号', this.phone)
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  InfoItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#666666')
        .width(80)

      Text(value)
        .fontSize(16)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding(15)
  }
}