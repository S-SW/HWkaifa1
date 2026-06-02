import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import ApiService from '../network/ApiService';
import { Address } from '../model/Entities';
import AuthGuard from '../utils/AuthGuard';

@Entry
@Component
struct AddressEdit {
  @State address: Address = new Address();
  @State isEdit: boolean = false;
  @State isLoading: boolean = false;
  @State isDefault: boolean = false;

  async aboutToAppear() {
    const hasAuth = await AuthGuard.checkAuthAndRedirect('pages/addressEdit');
    if (!hasAuth) {
      return;
    }
    let params = router.getParams() as Record<string, string | number>;
    if (params && params.address) {
      let addrStr = params.address.toString();
      if (addrStr.startsWith('{')) {
        this.address = JSON.parse(addrStr) as Address;
      }
      this.isEdit = true;
      this.isDefault = this.address.isDefault;
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

        Text(this.isEdit ? '编辑地址' : '新增地址')
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

      Column() {
        Row() {
          Text('收货人')
            .fontSize(14)
            .fontColor('#666666')
            .width(70)

          TextInput({ placeholder: '请输入收货人姓名', text: this.address.contactName })
            .layoutWeight(1)
            .fontSize(14)
            .backgroundColor('#FFFFFF')
            .borderRadius(0)
            .onChange((value: string) => {
              this.address.contactName = value;
            })
        }
        .width('100%')
        .padding({ left: 15, right: 15, top: 15 })

        Divider()
          .width('90%')
          .margin({ left: 85, top: 15 })

        Row() {
          Text('手机号')
            .fontSize(14)
            .fontColor('#666666')
            .width(70)

          TextInput({ placeholder: '请输入手机号', text: this.address.contactPhone })
            .layoutWeight(1)
            .fontSize(14)
            .type(InputType.PhoneNumber)
            .backgroundColor('#FFFFFF')
            .borderRadius(0)
            .onChange((value: string) => {
              this.address.contactPhone = value;
            })
        }
        .width('100%')
        .padding({ left: 15, right: 15, top: 15 })

        Divider()
          .width('90%')
          .margin({ left: 85, top: 15 })

        Row() {
          Text('详细地址')
            .fontSize(14)
            .fontColor('#666666')
            .width(70)
            .alignSelf(ItemAlign.Start)
        }

        Column() {
          TextArea({ placeholder: '请输入详细地址', text: this.address.detailAddress })
            .width('100%')
            .height(80)
            .fontSize(14)
            .backgroundColor('#FFFFFF')
            .borderRadius(0)
            .onChange((value: string) => {
              this.address.detailAddress = value;
            })
        }
        .layoutWeight(1)
        .padding({ left: 15, right: 15, top: 15 })

        Divider()
          .width('90%')
          .margin({ left: 85 })

        Row() {
          Text('设为默认')
            .fontSize(14)
            .fontColor('#666666')

          Blank()

          Checkbox()
            .select(this.isDefault)
            .onChange((value: boolean) => {
              this.isDefault = value;
              this.address.isDefault = value;
            })
        }
        .width('100%')
        .padding({ left: 15, right: 15, top: 15 })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .layoutWeight(1)

      Row() {
        Button(this.isLoading ? '保存中...' : '保存地址')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF6B35')
          .borderRadius(25)
          .width('90%')
          .height(50)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.saveAddress();
          })
      }
      .width('100%')
      .height(80)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#FFFFFF')
      .shadow({
        radius: 10,
        color: '#20000000',
        offsetX: 0,
        offsetY: -2
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  async saveAddress() {
    if (!this.address.contactName || this.address.contactName.trim() === '') {
      promptAction.showToast({ message: '请输入收货人姓名', duration: 2000 });
      return;
    }

    if (!this.address.contactPhone || this.address.contactPhone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号', duration: 2000 });
      return;
    }

    if (!this.address.detailAddress || this.address.detailAddress.trim() === '') {
      promptAction.showToast({ message: '请输入详细地址', duration: 2000 });
      return;
    }

    this.isLoading = true;

    try {
      let success: boolean;
      if (this.isEdit) {
        success = await ApiService.updateAddress(this.address);
      } else {
        success = await ApiService.addAddress(this.address);
      }

      if (success) {
        promptAction.showToast({ message: '保存成功', duration: 1500 });
        setTimeout(() => {
          router.back();
        }, 500);
      }
    } catch (e) {
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }
}