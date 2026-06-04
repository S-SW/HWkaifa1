import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import ApiService from '../network/ApiService';
import { Address as AddressModel } from '../model/Entities';
import AuthGuard from '../utils/AuthGuard';

@Entry
@Component
struct Address {
  @State addresses: AddressModel[] = [];
  @State isLoading: boolean = false;

  async aboutToAppear() {
    const hasAuth = await AuthGuard.checkAuthAndRedirect('pages/address');
    if (hasAuth) {
      this.loadAddresses();
    }
  }

  // 👈 核心新增功能：每次从新增/编辑页 router.back() 返回到这个界面时，本方法会被自动触发
  async onPageShow() {
    const hasAuth = await AuthGuard.checkAuthAndRedirect('pages/address');
    if (hasAuth) {
      this.loadAddresses(); // 强制重新向后端请求最新加入的数据，完成自动刷新
    }
  }

  async loadAddresses() {
    this.isLoading = true;
    try {
      this.addresses = await ApiService.getAddressList();
    } catch (e) {
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
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

        Text('地址管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('新增')
          .fontSize(16)
          .fontColor('#FF6B35')
          .onClick(() => {
            router.pushUrl({ url: 'pages/addressEdit' });
          })
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#FF6B35')
          Text('正在加载地址...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 10 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.addresses.length === 0) {
        Column() {
          Text('暂无收货地址')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.addresses, (address: AddressModel) => {
            ListItem() {
              this.AddressCard(address)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 15, right: 15, top: 10, bottom: 10 })
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  AddressCard(address: AddressModel) {
    Column() {
      Row() {
        Text(address.contactName)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Text(address.contactPhone)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: 15 })

        if (address.isDefault) {
          Text('默认')
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF6B35')
            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
            .borderRadius(3)
            .margin({ left: 10 })
        }
      }
      .width('100%')
      .padding({ left: 15, right: 15, top: 15, bottom: 5 })

      Row() {
        Text(address.detailAddress)
          .fontSize(14)
          .fontColor('#333333')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: 15, right: 15, bottom: 15 })

      Divider()
        .color('#EEEEEE')
        .strokeWidth(1)
        .margin({ left: 15, right: 15 })

      Row() {
        Row() {
          Image(address.isDefault ? $r('app.media.icon') : $r('app.media.icon')) // 使用你的单选图标资源代替
            .width(16)
            .height(16)
            .onClick(() => {
              if (!address.isDefault) {
                this.setDefaultAddress(address);
              }
            })

          Text('设为默认地址')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 8 })
        }

        Blank()

        Row() {
          Text('编辑')
            .fontSize(12)
            .fontColor('#666666')
            .onClick(() => {
              this.editAddress(address);
            })

          Text('删除')
            .fontSize(12)
            .fontColor('#FF3B30')
            .margin({ left: 20 })
            .onClick(() => {
              this.deleteAddress(address);
            })
        }
        .padding({ left: 15, right: 15, bottom: 15 })
      }
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .margin({ bottom: 10 })
  }

  editAddress(address: AddressModel) {
    router.pushUrl({
      url: 'pages/addressEdit',
      params: { address: JSON.stringify(address) } // 序列化传输更安全稳定
    });
  }

  async deleteAddress(address: AddressModel) {
    try {
      let success = await ApiService.deleteAddress(address.id);
      if (success) {
        let index = this.addresses.indexOf(address);
        if (index > -1) {
          this.addresses.splice(index, 1);
        }
        promptAction.showToast({ message: '删除成功', duration: 1500 });
      }
    } catch (e) {
      promptAction.showToast({ message: '删除失败', duration: 1500 });
    }
  }

  async setDefaultAddress(address: AddressModel) {
    try {
      address.isDefault = true;
      let success = await ApiService.updateAddress(address);
      if (success) {
        promptAction.showToast({ message: '设置默认地址成功', duration: 1500 });
        this.loadAddresses();
      }
    } catch (e) {
      promptAction.showToast({ message: '设置失败', duration: 1500 });
    }
  }
}