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
          .margin({ left: 15 })

        Blank()
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#FFFFFF')

      List() {
        ListItem() {
          Row() {
            Text('收货人')
              .fontSize(16)
              .width(80)
            TextInput({ text: this.address.contactName, placeholder: '请填写收货人姓名' })
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .onChange((value: string) => {
                this.address.contactName = value;
              })
          }
          .width('100%')
          .padding({ top: 15, bottom: 15 })
        }

        ListItem() {
          Row() {
            Text('手机号码')
              .fontSize(16)
              .width(80)
            TextInput({ text: this.address.contactPhone, placeholder: '请填写收货人手机号' })
              .layoutWeight(1)
              .type(InputType.PhoneNumber)
              .backgroundColor(Color.Transparent)
              .onChange((value: string) => {
                this.address.contactPhone = value;
              })
          }
          .width('100%')
          .padding({ top: 15, bottom: 15 })
        }

        ListItem() {
          Row() {
            Text('详细地址')
              .fontSize(16)
              .width(80)
            TextInput({ text: this.address.detailAddress, placeholder: '例：临港校区几栋几零几' })
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .onChange((value: string) => {
                this.address.detailAddress = value;
              })
          }
          .width('100%')
          .padding({ top: 15, bottom: 15 })
        }

        ListItem() {
          Row() {
            Text('设为默认地址')
              .fontSize(16)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.isDefault })
              .selectedColor('#FF6B35')
              .onChange((isOn: boolean) => {
                this.isDefault = isOn;
                this.address.isDefault = isOn;
              })
          }
          .width('100%')
          .padding({ top: 15, bottom: 15 })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 15, right: 15 })
      .backgroundColor('#FFFFFF')
      .margin({ top: 10 })

      Row() {
        Button(this.isLoading ? '正在保存...' : '保存并使用')
          .width('90%')
          .height(45)
          .backgroundColor('#FF6B35')
          .fontColor('#FFFFFF')
          .fontSize(16)
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
      let success: boolean = false;
      if (this.isEdit) {
        success = await ApiService.updateAddress(this.address);
      } else {
        success = await ApiService.addAddress(this.address);
      }

      // 👈 核心增强修复：只要接口返回成功，强制弹窗提示并执行返回
      if (success) {
        promptAction.showToast({ message: '保存成功', duration: 2000 });
        setTimeout(() => {
          router.back();
        }, 500); // 稍微延时半秒，给用户看清楚“保存成功”的提示，体验更好
      } else {
        promptAction.showToast({ message: '保存失败，请检查网络', duration: 2000 });
      }
    } catch (e) {
      promptAction.showToast({ message: '网络错误，保存失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }
}