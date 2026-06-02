import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import ApiService from '../network/ApiService';
import { Order, OrderItem } from '../model/Entities';
import AuthGuard from '../utils/AuthGuard';

@Entry
@Component
struct OrderDetail {
  @State order: Order = new Order();
  @State isLoading: boolean = false;

  async aboutToAppear() {
    const hasAuth = await AuthGuard.checkAuthAndRedirect('pages/orderDetail');
    if (!hasAuth) {
      return;
    }
    let params = router.getParams() as Record<string, number>;
    if (params && params.orderId) {
      this.loadOrderDetail(params.orderId);
    }
  }

  async loadOrderDetail(orderId: number) {
    this.isLoading = true;
    try {
      this.order = await ApiService.getOrderById(orderId);
      console.log(this.order.address?.detailAddress)
      console.log("order"+this.order.address?.toString())
    } catch (e) {
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
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

  build() {

    Column() {
      Row() {
        Image($r('app.media.ic_backward'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })

        Text('订单详情')
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
                Image($r('app.media.icon'))
                  .width(50)
                  .height(50)
                  .fillColor('#FF6B35')

                Column() {
                  Text(this.getStatusText(this.order.status))
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')

                  Text('订单号：' + this.order.orderNo)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 5 })
                }
                .margin({ left: 15 })
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(20)
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .margin({ top: 10 })

            Column() {
              Row() {
                Image($r('app.media.icon'))
                  .width(20)
                  .height(20)
                  .fillColor('#FF6B35')

                Text('配送地址')
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ left: 8 })
              }
              .width('100%')

              Text( this.order.address
                ? this.order.address.detailAddress +' ' + this.order.address.contactName +' '+ this.order.address.contactPhone
                : "暂无地址信息")
                .fontSize(14)
                .fontColor('#333333')
                .width('100%')
                .margin({ top: 10 })
            }
            .width('100%')
            .padding(15)
            .backgroundColor('#FFFFFF')
            .margin({ top: 10 })

            Column() {
              Text('订单信息')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .width('100%')
                .padding(15)

              Column() {
                Row() {
                  Text('下单时间')
                    .fontSize(14)
                    .fontColor('#666666')

                  Blank()

                  Text(this.order.createdAt || '暂无')
                    .fontSize(14)
                    .fontColor('#333333')
                }
                .width('100%')
                .padding({ left: 15, right: 15, top: 10 })

                Row() {
                  Text('菜品金额')
                    .fontSize(14)
                    .fontColor('#666666')

                  Blank()

                  Text('¥' + (this.order.dishAmount || 0).toFixed(2))
                    .fontSize(14)
                    .fontColor('#333333')
                }
                .width('100%')
                .padding({ left: 15, right: 15, top: 10 })

                Row() {
                  Text('配送金额')
                    .fontSize(14)
                    .fontColor('#666666')

                  Blank()

                  Text('¥' + (this.order.deliveryAmount || 0).toFixed(2))
                    .fontSize(14)
                    .fontColor('#333333')
                }
                .width('100%')
                .padding({ left: 15, right: 15, top: 5 })

                Row() {
                  Text('订单总金额')
                    .fontSize(14)
                    .fontColor('#666666')

                  Blank()

                  Text('¥' + (this.order.totalAmount || 0).toFixed(2))
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FF6B35')
                }
                .width('100%')
                .padding({ left: 15, right: 15, top: 10, bottom: 15 })
              }
              .width('100%')
              .backgroundColor('#F9F9F9')
              .borderRadius(10)
            }
            .width('100%')
            .padding(15)
            .backgroundColor('#FFFFFF')
            .margin({ top: 10 })

            Column() {
              Text('订单菜品')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .width('100%')
                .padding(15)

              if (this.order.items && this.order.items.length > 0) {
                ForEach(this.order.items, (item: OrderItem) => {
                  Row() {
                    Image(item.imageUrl || $r('app.media.icon'))
                      .width(60)
                      .height(60)
                      .borderRadius(8)

                    Column() {
                      Text(item.dishName)
                        .fontSize(14)
                        .fontColor('#333333')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      Text('x' + item.quantity)
                        .fontSize(12)
                        .fontColor('#999999')
                        .margin({ top: 5 })
                    }
                    .layoutWeight(1)
                    .margin({ left: 10 })
                    .alignItems(HorizontalAlign.Start)

                    Text('¥' + (item.price * item.quantity))
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#333333')
                  }
                  .width('100%')
                  .padding({ left: 15, right: 15, bottom: 10 })
                })
              } else {
                Text('暂无菜品信息')
                  .fontSize(14)
                  .fontColor('#999999')
                  .padding(15)
              }
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .margin({ top: 10 })
          }
        }
        .align(Alignment.Top)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .layoutWeight(1)

        if (this.order.status === 0) {
          Row() {
            Blank()

            Button('取消订单')
              .fontSize(14)
              .fontColor('#666666')
              .backgroundColor('#F5F5F5')
              .borderRadius(20)
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .margin({ right: 10 })
              .onClick(() => {
                this.cancelOrder();
              })

            Button('支付')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#FF6B35')
              .borderRadius(20)
              .padding({ left: 30, right: 30, top: 10, bottom: 10 })
              .onClick(() => {
                this.payOrder();
              })
          }
          .width('100%')
          .height(70)
          .padding({ left: 15, right: 15 })
          .backgroundColor('#FFFFFF')
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  cancelOrder() {
    promptAction.showToast({ message: '取消订单功能开发中', duration: 2000 });
  }

  payOrder() {
    promptAction.showToast({ message: '支付功能开发中', duration: 2000 });
  }
}