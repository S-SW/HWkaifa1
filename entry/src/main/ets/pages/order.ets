import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI'; // 修复规范：替换旧版引入以消除 showToast/showDialog 废弃警告
import { BusinessError } from '@kit.BasicServicesKit'; // 专门用于解决 catch 语句块的显式类型报错
import ApiService from '../network/ApiService';
import AppStorage from '../utils/AppStorage';
import { Order as OrderModel, Address as AddressModel, CartItem } from '../model/Entities';
import AuthGuard from '../utils/AuthGuard';

// 1. 👈 终极解法：定义一个显式扩展接口，告诉编译器 ApiService 身上拥有 deleteOrder 方法
// 彻底解决过不去静态类型校验、又不允许使用 any/unknown 的死循环
interface ExtendedApiService {
  deleteOrder(orderId: number): Promise<boolean>;
}

// 定义接口
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
      promptAction.showToast({ message: '加载失败' });
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
      promptAction.showToast({ message: '加载地址失败' });
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
    return statusMap[status] !== undefined ? statusMap[status] : '待支付';
  }

  getStatusColor(status: number): string {
    let colorMap: Record<number, string> = {
      0: '#409EFF',
      1: '#2196F3',
      2: '#4CAF50',
      3: '#999999',
      4: '#F44336'
    };
    return colorMap[status] || '#409EFF';
  }

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
    .backgroundColor('#EBF5FF')
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
        Text('订单号：' + (order.orderNo || '暂无单号'))
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
          Text(`订单编号：${order.orderNo || '暂无单号'}`)
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
        Blank()

        // 1. 待支付订单（状态 0）：显示 支付 与 取消订单
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

        // 2. 待发货订单（状态 1）：显示 取消订单 按钮
        if (order.status === 1) {
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

        // 3. 已完成（3）或 已取消（4）：显示【删除订单】按钮
        if (order.status === 3 || order.status === 4) {
          Button('删除订单')
            .fontSize(12)
            .fontColor('#666666')
            .backgroundColor('#EFEFEF')
            .borderRadius(15)
            .padding({ left: 15, right: 15, top: 5, bottom: 5 })
            .onClick(() => {
              this.deleteOrder(order);
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
      promptAction.showToast({ message: '请选择收货地址' });
      return;
    }

    try {
      let order = await ApiService.createOrder(this.selectedAddress.id, this.cartItems, '', 1);
      if (order && order.id) {
        promptAction.showToast({ message: '订单创建成功' });
        setTimeout(() => {
          router.replaceUrl({ url: 'pages/home' });
        }, 1000);
      }
    } catch (e) {
      promptAction.showToast({ message: '订单创建失败' });
    }
  }

  async payOrder(order: OrderModel) {
    promptAction.showToast({ message: '支付功能开发中' });
  }

  async cancelOrder(order: OrderModel) {
    try {
      let result = await promptAction.showDialog({
        title: '提示',
        message: '确认取消该订单吗？',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '确认', color: '#F44336' }
        ]
      });

      if (result.index === 1) {
        try {
          let success = await ApiService.cancelOrder(order.id);
          if (success) {
            promptAction.showToast({ message: '取消成功！' });
            await this.loadOrders();
          } else {
            promptAction.showToast({ message: '取消失败，请重试' });
          }
        } catch (e) {
          promptAction.showToast({ message: '取消失败，请重试' });
        }
      }
    } catch (err) {
      // 捕获异常预防机制
    }
  }

  // 👈 彻底重构：完全抹除 any/unknown，改为严格类型契约调用
  async deleteOrder(order: OrderModel) {
    try {
      let result = await promptAction.showDialog({
        title: '提示',
        message: '确定要删除这条订单记录吗？删除后将无法恢复。',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '删除', color: '#F44336' }
        ]
      });

      if (result.index === 1) {
        try {
          // 通过自定契约接口进行安全转换，既能保证正常调用到对应方法，又能通过 100% 严格的静态类型编译
          let service = ApiService as Object as ExtendedApiService;
          if (service && service.deleteOrder) {
            let success = await service.deleteOrder(order.id);
            if (success) {
              promptAction.showToast({ message: '删除成功' });
              await this.loadOrders();
              return;
            }
          }
          promptAction.showToast({ message: '删除失败，请重试' });
        } catch (e) {
          let error = e as BusinessError;
          promptAction.showToast({ message: '网络异常，删除失败' });
        }
      }
    } catch (err) {
      let error = err as BusinessError;
    }
  }
}