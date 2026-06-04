import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct Splash {
  @State logoOpacity: number = 1;
  @State logoScale: number = 0.5;
  @State contentOpacity: number = 1;
  @State isAnimating: boolean = false;

  aboutToAppear() {
    this.startAnimation();
  }

  startAnimation() {
    setTimeout(() => {
      this.isAnimating = true;
      animateTo({
        duration: 800,
        curve: Curve.EaseOut,
        iterations: 1,
        playMode: PlayMode.Normal
      }, () => {
        this.logoOpacity = 1;
        this.logoScale = 1;
      });

      setTimeout(() => {
        animateTo({
          duration: 500,
          curve: Curve.EaseIn,
          iterations: 1,
          playMode: PlayMode.Normal
        }, () => {
          this.contentOpacity = 1;
        });
      }, 600);

      setTimeout(() => {
        this.navigateToHome();
      }, 2500);
    }, 200);
  }

  navigateToHome() {
    // promptAction.showToast({
    //   message: '欢迎使用食堂订餐系统',
    //   duration: 1500
    // });

    setTimeout(() => {
      router.replaceUrl({
        url: 'pages/home'
      });
    }, 500);
  }

  build() {
    Stack() {
      Column() {
        Image($r('app.media.icon'))
          .width(120)
          .height(120)
          .opacity(this.logoOpacity)
          .scale({ x: this.logoScale, y: this.logoScale })

        Text('食堂订餐')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ top: 20 })
          .opacity(this.contentOpacity)

        Text('让用餐更便捷')
          .fontSize(16)
          .fontColor('#F1F2F6')
          .margin({ top: 10 })
          .opacity(this.contentOpacity)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#ff89eafa')
    }
    .width('100%')
    .height('100%')
  }
}