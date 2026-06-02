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
          .fontSize(14)
          .fontColor('#FF6B35')
          .onClick(() => {
            router.pushUrl({ url: 'pages/addressEdit' });
          })
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
      } else if (this.addresses.length === 0) {
        Blank()
        Column() {
          Image($r('app.media.icon'))
            .width(80)
            .height(80)
            .opacity(0.5)

          Text('暂无地址')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 20 })

          Text('点击右上角添加新地址')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .margin({ top: 10 })
        }
      } else {
        Scroll() {
          Column() {
            ForEach(this.addresses, (address: AddressModel) => {
              this.AddressCard(address)
            })
          }
          .padding(15)
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
  AddressCard(address: AddressModel) {
    Column() {
      Row() {
        Column() {
          Text(address.contactName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          Text(address.contactPhone)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 5 })

          Text(address.detailAddress)
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 5 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column() {
          if (address.isDefault) {
            Text('默认')
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor('#FF6B35')
              .borderRadius(10)
              .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          }

          Row() {
            Image($r('app.media.icon'))
              .width(20)
              .height(20)
              .fillColor('#FF6B35')
              .onClick(() => {
                this.editAddress(address);
              })

            Image($r('app.media.icon'))
              .width(20)
              .height(20)
              .fillColor('#F44336')
              .margin({ left: 15 })
              .onClick(() => {
                this.deleteAddress(address);
              })
          }
          .margin({ top: 10 })
        }
      }
      .width('100%')
      .padding(15)

      if (!address.isDefault) {
        Row() {
          Checkbox()
            .select(address.isDefault)
            .onChange((isSelected: boolean) => {
              if (isSelected) {
                this.setDefaultAddress(address);
              }
            })

          Text('设为默认地址')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 8 })
        }
        .width('100%')
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
      params: { address: address }
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
        this.addresses.forEach(a => {
          if (a.id !== address.id) {
            a.isDefault = false;
          }
        });
        promptAction.showToast({ message: '设置成功', duration: 1500 });
      }
    } catch (e) {
      promptAction.showToast({ message: '设置失败', duration: 1500 });
    }
  }
}