import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import ApiService from '../network/ApiService';
import AppStorage from '../utils/AppStorage';
import { Order as OrderModel, Address as AddressModel, CartItem } from '../model/Entities';
import AuthGuard from '../utils/AuthGuard';

// 先定义接口
interface OrderParams {
  totalPrice: number;
  totalCount: number;
  cartItems: CartItem[];
}

@Entry
@Component
struct Order {
  @State orders: OrderModel[] = [];
  @State isLoading: boolean = false;
  @State currentTab: number = 0;
  @State addresses: AddressModel[] = [];
  @State selectedAddress: AddressModel | null = null;
  @State totalPrice: number = 0;
  @State isCreateMode: boolean = false;
  @State totalCount: number = 0;
  @State cartItems: CartItem[] = [];

  async aboutToAppear() {
    const hasAuth = await AuthGuard.checkAuthAndRedirect('pages/order');
    if (!hasAuth) {
      return;
    }
    let params = router.getParams() as OrderParams;

    if (params) {
      if (params.totalPrice) {
        this.totalPrice = params.totalPrice;
      }
      if (params.totalCount) {
        this.totalCount = params.totalCount;
      }

      this.cartItems = params.cartItems;
      this.isCreateMode = true;
      this.loadAddresses();
    } else {
      this.loadOrders();
    }
  }

  async loadOrders() {
    this.isLoading = true;
    try {
      this.orders = await ApiService.getOrderList();
    } catch (e) {
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async loadAddresses() {
    try {
      this.addresses = await ApiService.getAddressList();
      if (this.addresses.length > 0) {
        let defaultAddr = this.addresses.find(a => a.isDefault);
        this.selectedAddress = defaultAddr || this.addresses[0];
      }
    } catch (e) {
      promptAction.showToast({ message: '加载地址失败', duration: 2000 });
    }
  }

  getStatusText(status: number): string {
    let statusMap: Record<number, string> = {
      0: '待支付',
      1: '待发货',
      2: '待收货',
      3: '已完成',
      4: '已取消'
    };
    return statusMap[status] || '未知';
  }

  getStatusColor(status: number): string {
    let colorMap: Record<number, string> = {
      0: '#409EFF',
      1: '#2196F3',
      2: '#4CAF50',
      3: '#999999',
      4: '#F44336'
    };
    return colorMap[status] || '#999999';
  }

  // 辅助方法：根据状态筛选订单
  getFilteredOrders(status: number): OrderModel[] {
    if (status === -1) {
      return this.orders;
    }
    return this.orders.filter(order => order.status === status);
  }

  build() {
    Column() {
      if (this.isCreateMode) {
        this.CreateOrderView()
      } else {
        this.OrderListView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  CreateOrderView() {
    Column() {
      Row() {
        Image($r('app.media.icon'))
          .width(24)
          .height(24)
          .onClick(() => {
            if (this.isCreateMode) {
              router.back();
            }
          })

        Text('确认订单')
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

      Scroll() {
        Column() {
          Row() {
            Image($r('app.media.icon'))
              .width(40)
              .height(40)
              .fillColor('#409EFF')

            Column() {
              if (this.selectedAddress != null) {
                Text(this.selectedAddress.contactName + ' ' + this.selectedAddress.contactPhone)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#333333')

                Text(this.selectedAddress.detailAddress)
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ top: 5 })
              } else {
                Text('请添加收货地址')
                  .fontSize(16)
                  .fontColor('#409EFF')
              }
            }
            .layoutWeight(1)
            .margin({ left: 15 })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .margin(15)
          .onClick(() => {
            router.pushUrl({ url: 'pages/address' });
          })

          Column() {
            Text('订单菜品')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .padding(15)

            Row() {
              Text('菜品信息')
                .fontSize(14)
                .fontColor('#666666')

              Blank()

              Text('共' + this.totalCount + '件')
                .fontSize(14)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: 15, right: 15 })
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ left: 15, right: 15 })
          .borderRadius(10)
        }
      }
      .align(Alignment.Top)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .layoutWeight(1)

      Row() {
        Column() {
          Text('合计')
            .fontSize(14)
            .fontColor('#666666')

          Text('¥' + this.totalPrice.toFixed(2))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#409EFF')
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 15 })

        Blank()

        Button('提交订单')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#409EFF')
          .borderRadius(25)
          .padding({ left: 30, right: 30, top: 12, bottom: 12 })
          .margin({ right: 15 })
          .onClick(() => {
            this.submitOrder();
          })
      }
      .width('100%')
      .height(80)
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)
      .shadow({
        radius: 10,
        color: '#20000000',
        offsetX: 0,
        offsetY: -2
      })
    }
  }

  @Builder
  OrderListView() {
    Column() {
      Row() {
        Image($r('app.media.ic_backward'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })

        Text('我的订单')
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

      Tabs({ index: this.currentTab }) {
        TabContent() {
          this.OrderListByStatus(-1)
        }
        .tabBar('全部')

        TabContent() {
          this.OrderListByStatus(0)
        }
        .tabBar('待支付')

        TabContent() {
          this.OrderListByStatus(3)
        }
        .tabBar('已完成')
      }
      .width('100%')
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentTab = index;
      })
    }
  }

  @Builder
  OrderListByStatus(status: number) {
    if (this.isLoading) {
      Blank()
      LoadingProgress()
        .width(40)
        .height(40)
    } else {
      // 使用辅助方法获取筛选后的订单
      if (this.getFilteredOrders(status).length === 0) {
        Blank()
        Column() {
          Image($r('app.media.icon'))
            .width(80)
            .height(80)
            .opacity(0.5)

          Text('暂无订单')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 20 })
        }
        .layoutWeight(1)
      } else {
        Scroll() {
          Column() {
            ForEach(this.getFilteredOrders(status), (order: OrderModel) => {
              this.OrderCard(order)
            }, (order: OrderModel) => order.id.toString())
          }
          .padding(15)
        }
        .align(Alignment.Top)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
    }
  }

  @Builder
  OrderCard(order: OrderModel) {
    Column() {
      Row() {
        Text('订单号：' + order.orderNo)
          .fontSize(12)
          .fontColor('#999999')

        Blank()

        Text(this.getStatusText(order.status))
          .fontSize(14)
          .fontColor(this.getStatusColor(order.status))
      }
      .width('100%')
      .padding(15)

      Divider()
        .width('90%')

      Row() {
        Column() {
          Text(`订单金额：¥${order.totalAmount}`)
            .fontSize(14)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)

        Text('¥' + order.totalAmount)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#409EFF')
      }
      .width('100%')
      .padding(15)

      Row() {
        Text(`订单编号：${order.orderNo}`)
          .fontSize(12)
          .fontColor('#999999')

        Blank()

        // 支付按钮（仅待支付状态显示）
        if (order.status === 0) {
          Button('支付')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#409EFF')
            .borderRadius(15)
            .padding({ left: 15, right: 15, top: 5, bottom: 5 })
            .margin({ right: 8 })
            .onClick(() => {
              this.payOrder(order);
            })
        }

        // 取消订单按钮（待支付 或 待发货状态可取消）
        if (order.status === 0 || order.status === 1) {
          Button('取消订单')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#F44336')
            .borderRadius(15)
            .padding({ left: 15, right: 15, top: 5, bottom: 5 })
            .onClick(() => {
              this.cancelOrder(order);
            })
        }
      }
      .width('100%')
      .padding({ left: 15, right: 15, bottom: 15 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .margin({ bottom: 10 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/orderDetail',
        params: { orderId: order.id }
      });
    })
  }

  async submitOrder() {
    if (!this.selectedAddress) {
      promptAction.showToast({ message: '请选择收货地址', duration: 2000 });
      return;
    }

    try {
      let order = await ApiService.createOrder(this.selectedAddress.id, this.cartItems, '', 1);
      if (order && order.id) {
        promptAction.showToast({ message: '订单创建成功', duration: 2000 });
        setTimeout(() => {
          router.replaceUrl({ url: 'pages/home' });
        }, 1000);
      }
    } catch (e) {
      promptAction.showToast({ message: '订单创建失败', duration: 2000 });
    }
  }

  async payOrder(order: OrderModel) {
    promptAction.showToast({ message: '支付功能开发中', duration: 2000 });
  }

  async cancelOrder(order: OrderModel) {
    // 显示确认对话框
    promptAction.showDialog({
      title: '提示',
      message: '确认取消该订单吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确认', color: '#F44336' }
      ]
    }).then(async (result) => {
      if (result.index === 1) { // 确认按钮
        try {
          // 调用API取消订单
          let success = await ApiService.cancelOrder(order.id);
          if (success) {
            promptAction.showToast({ message: '取消成功！', duration: 2000 });
            // 刷新订单列表
            await this.loadOrders();
          } else {
            promptAction.showToast({ message: '取消失败，请重试', duration: 2000 });
          }
        } catch (e) {
          promptAction.showToast({ message: '取消失败，请重试', duration: 2000 });
        }
      }
    }).catch(() => {
      // 用户取消对话框
    });
  }
}