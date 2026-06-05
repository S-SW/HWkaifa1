// pages/address.ets
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

  // 👈 自动刷新功能完美保持不变
  async onPageShow() {
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
      // 顶部导航栏 - 改为深蓝底色
      Row() {
        Image($r('app.media.ic_backward'))
          .width(22)
          .height(22)
          .onClick(() => {
            router.back();
          })

        Text('地址管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ left: 10 })

        Text('新增')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF') // 改为白色以融入深蓝导航栏
          .onClick(() => {
            router.pushUrl({ url: 'pages/addressEdit' });
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#409EFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(45)
            .height(45)
            .color('#409EFF') // 改为深蓝加载图标
          Text('正在加载地址...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.addresses.length === 0) {
        Column() {
          Text('暂无收货地址')
            .fontSize(15)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.addresses, (address: AddressModel) => {
            ListItem() {
              this.AddressCard(address)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 14, bottom: 14 })
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E6F4F8') // 改为统一的舒适清爽浅蓝色底色
  }

  @Builder
  AddressCard(address: AddressModel) {
    Column() {
      // 姓名、电话、默认标签
      Row() {
        Text(address.contactName)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Text(address.contactPhone)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: 12 })

        if (address.isDefault) {
          Text('默认')
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor('#409EFF') // 默认标签同步改为深蓝色
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
            .margin({ left: 10 })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      // 详细地址
      Row() {
        Text(address.detailAddress)
          .fontSize(14)
          .fontColor('#555555')
          .maxLines(2)
          .lineHeight(20)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })

      Divider()
        .color('#EDF2F7')
        .strokeWidth(1)
        .margin({ left: 16, right: 16 })

      // 底部操作栏 - 修复排版对齐
      Row() {
        Row() {
          Image(address.isDefault ? $r('app.media.pencil') : $r('app.media.mr'))
            .width(18)
            .height(18)
            .fillColor(address.isDefault ? '#409EFF' : '#CCCCCC') // 默认勾选高亮蓝色
            .onClick(() => {
              if (!address.isDefault) {
                this.setDefaultAddress(address);
              }
            })

          Text('设为默认地址')
            .fontSize(13)
            .fontColor(address.isDefault ? '#409EFF' : '#666666')
            .margin({ left: 8 })
        }

        Blank()

        Row() {
          Text('编辑')
            .fontSize(13)
            .fontColor('#666666')
            .onClick(() => {
              this.editAddress(address);
            })

          Text('删除')
            .fontSize(13)
            .fontColor('#FF3B30') // 保持红色危险警告色
            .margin({ left: 20 })
            .onClick(() => {
              // 触发带有确认按钮的弹窗
              this.showDeleteConfirm(address);
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 }) // 修正原先将 padding 误加给 Row 的错位问题
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: '#08000000', offsetX: 0, offsetY: 4 }) // 融入微阴影
  }

  editAddress(address: AddressModel) {
    router.pushUrl({
      url: 'pages/addressEdit',
      params: { address: JSON.stringify(address) }
    });
  }

  // 修改后的删除核心逻辑：删除成功后调用 loadAddresses() 实现全自动刷新
  async deleteAddress(address: AddressModel) {
    try {
      let success = await ApiService.deleteAddress(address.id);
      if (success) {
        promptAction.showToast({ message: '删除成功', duration: 1500 });

        // 👈 核心改动：不再手动写 splice，直接重新加载后端最新数据，确保状态百分之百同步刷新
        this.loadAddresses();
      }
    } catch (e) {
      promptAction.showToast({ message: '删除失败', duration: 1500 });
    }
  }

  // 二次确认弹窗保持不变，它会自动去触发上面的 deleteAddress
  showDeleteConfirm(address: AddressModel) {
    promptAction.showDialog({
      title: '提示',
      message: '确定要删除该收货地址吗？',
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '确定', color: '#FF3B30' }
      ]
    }).then((data) => {
      if (data.index === 1) {
        this.deleteAddress(address);
      }
    });
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