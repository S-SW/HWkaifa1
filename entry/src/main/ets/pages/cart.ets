import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import hilog from '@ohos.hilog';
import ApiService from '../network/ApiService';
import { CartItem } from '../model/Entities';
import AuthGuard from '../utils/AuthGuard';

@Entry
@Component
struct Cart {
  @State cartItems: CartItem[] = [];
  @State isLoading: boolean = false;
  @State selectedItems: Set<number> = new Set();

  async aboutToAppear() {
    const hasAuth = await AuthGuard.checkAuthAndRedirect('pages/cart');
    if (hasAuth) {
      this.loadCart();
    }
  }

  async onPageShow() {
    const hasAuth = await AuthGuard.checkAuthAndRedirect('pages/cart');
    if (hasAuth) {
      this.loadCart();
    }
  }

  async loadCart() {
    this.isLoading = true;
    try {
      this.cartItems = await ApiService.getCartList();
      hilog.info(0x0000, 'Cart', '购物车数据: %{public}s', JSON.stringify(this.cartItems));
      this.cartItems.forEach(item => {
        console.log('item对象:', JSON.stringify(item));
        console.log('dish属性:', item?.dish);
        console.log('price值:', item?.dish?.price);
      });
      this.selectedItems = new Set(this.cartItems.map(item => item.id));
    } catch (e) {
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  getTotalPrice(): number {
    let total = 0;
    this.cartItems.forEach(item => {
      if (this.selectedItems.has(item.id)) {
        total += item.dish.price * item.quantity;
      }
    });
    return total;
  }

  getSelectedCount(): number {
    return this.selectedItems.size;
  }

  getTotalCount(): number {
    let total = 0;
    this.cartItems.forEach(item => {
      if (this.selectedItems.has(item.id)) {
        total += item.quantity;
      }
    });
    return total;
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Image($r('app.media.ic_backward'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          })

        Text('购物车')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        if (this.cartItems.length > 0) {
          Text('清空')
            .fontSize(14)
            .fontColor('#66B1FF') // 👈 改为浅蓝辅助色
            .onClick(() => {
              this.clearCart();
            })
        }
      }
      .width('100%')
      .height(60)
      .padding({ left: 15, right: 15 })
      .backgroundColor('#FFFFFF')

      // 主体内容区
      if (this.isLoading) {
        Blank()
        LoadingProgress()
          .width(40)
          .height(40)
          .color('#409EFF') // 👈 加载动画改为浅蓝色
      } else if (this.cartItems.length === 0) {
        Blank()
        Column() {
          Image($r('app.media.icon'))
            .width(100)
            .height(100)
            .opacity(0.5)

          Text('购物车是空的')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 20 })

          Text('去添加一些美食吧')
            .fontSize(14)
            .fontColor('#409EFF') // 👈 引导文字改为浅蓝色
            .margin({ top: 10 })
            .onClick(() => {
              router.replaceUrl({ url: 'pages/home' });
            })
        }
      } else {
        Scroll() {
          Column() {
            ForEach(this.cartItems, (item: CartItem) => {
              this.CartItemCard(item)
            }, (item: CartItem) => item.id.toString())
          }
          .padding({ bottom: 20 })
        }
        .align(Alignment.Top)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }

      // 底部结算栏
      if (this.cartItems.length > 0) {
        Row() {
          Row() {
            Checkbox()
              .select(this.selectedItems.size === this.cartItems.length)
              .selectedColor('#409EFF') // 👈 复选框选中色改为浅蓝
              .onChange((isSelected: boolean) => {
                if (isSelected) {
                  this.selectedItems = new Set(this.cartItems.map(item => item.id));
                } else {
                  this.selectedItems.clear();
                }
              })

            Text('全选')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ left: 8 })
          }

          Blank()

          Column() {
            Text('合计')
              .fontSize(14)
              .fontColor('#666666')

            Text('¥' + this.getTotalPrice().toFixed(2))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#409EFF') // 👈 金额高亮色改为浅蓝
          }
          .alignItems(HorizontalAlign.End)

          Button('去结算(' + this.getTotalCount() + ')')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#409EFF') // 👈 结算按钮底色改为浅蓝
            .borderRadius(20)
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .margin({ left: 15 })
            .enabled(this.getTotalCount() > 0)
            .onClick(() => {
              this.goToCheckout();
            })
        }
        .width('100%')
        .height(80)
        .padding({ left: 15, right: 15 })
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
    .width('100%')
    .height('100%')
    .backgroundColor('#EBF5FF') // 👈 整个页面的背景衬底色升级为舒适的极浅蓝色
  }

  @Builder
  CartItemCard(item: CartItem) {
    Row() {
      Checkbox()
        .select(this.selectedItems.has(item.id))
        .selectedColor('#409EFF') // 👈 列表内复选框选中色改为浅蓝
        .onChange((isSelected: boolean) => {
          const newSelectedItems = new Set(this.selectedItems);
          if (isSelected) {
            newSelectedItems.add(item.id);
          } else {
            newSelectedItems.delete(item.id);
          }
          this.selectedItems = newSelectedItems;
        })

      Image(item.dish.imageUrl || $r('app.media.icon'))
        .width(80)
        .height(80)
        .borderRadius(10)
        .margin({ left: 10 })

      Column() {
        Text(item.dish.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('¥' + item.dish.price)
          .fontSize(14)
          .fontColor('#409EFF') // 👈 列表菜品单价改为浅蓝高亮
          .margin({ top: 5 })
      }
      .layoutWeight(1)
      .padding({ left: 10 })
      .alignItems(HorizontalAlign.Start)

      Column() {
        Row() {
          Text('-')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(item.quantity > 1 ? '#333333' : '#CCCCCC')
            .width(28)
            .height(28)
            .textAlign(TextAlign.Center)
            .backgroundColor('#F5F5F5')
            .borderRadius(4)
            .onClick(() => {
              this.updateQuantity(item, -1);
            })

          Text(item.quantity.toString())
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .width(40)
            .textAlign(TextAlign.Center)

          Text('+')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .width(28)
            .height(28)
            .textAlign(TextAlign.Center)
            .backgroundColor('#409EFF') // 👈 数量加号底色改为浅蓝
            .borderRadius(4)
            .onClick(() => {
              this.updateQuantity(item, 1);
            })
        }

        Text('删除')
          .fontSize(12)
          .fontColor('#66B1FF') // 👈 每一项的删除按钮改为浅蓝辅助色
          .margin({ top: 8 })
          .onClick(() => {
            this.removeItem(item);
          })
      }
    }
    .width('100%')
    .padding(15)
    .margin({ top: 10, left: 15, right: 15 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12) // 👈 升级卡片化圆角，配合浅蓝底色质感更好
    .alignItems(VerticalAlign.Center)
  }

  async updateQuantity(item: CartItem, delta: number) {
    let newQuantity = item.quantity + delta;
    if (newQuantity < 1) {
      return;
    }

    try {
      await ApiService.updateCartItem(item.id, newQuantity);

      const updatedItems: CartItem[] = [];
      for (let i = 0; i < this.cartItems.length; i++) {
        if (this.cartItems[i].id === item.id) {
          const updatedItem = new CartItem();
          updatedItem.id = this.cartItems[i].id;
          updatedItem.userId = this.cartItems[i].userId;
          updatedItem.dishId = this.cartItems[i].dishId;
          updatedItem.quantity = newQuantity;
          updatedItem.createdAt = this.cartItems[i].createdAt;
          updatedItem.updatedAt = this.cartItems[i].updatedAt;
          updatedItem.dish = this.cartItems[i].dish;
          updatedItems.push(updatedItem);
        } else {
          updatedItems.push(this.cartItems[i]);
        }
      }

      this.cartItems = updatedItems;
    } catch (e) {
      promptAction.showToast({ message: '更新失败', duration: 1500 });
    }
  }

  async removeItem(item: CartItem) {
    try {
      await ApiService.removeFromCart(item.id);
      let index = this.cartItems.indexOf(item);
      if (index > -1) {
        this.cartItems.splice(index, 1);
      }
      const newSelectedItems = new Set(this.selectedItems);
      newSelectedItems.delete(item.id);
      this.selectedItems = newSelectedItems;
      promptAction.showToast({ message: '已删除', duration: 1500 });
    } catch (e) {
      promptAction.showToast({ message: '删除失败', duration: 1500 });
    }
  }

  async clearCart() {
    try {
      for (let item of this.cartItems) {
        await ApiService.removeFromCart(item.id);
      }
      this.cartItems = [];
      this.selectedItems.clear();
      promptAction.showToast({ message: '已清空', duration: 1500 });
    } catch (e) {
      promptAction.showToast({ message: '清空失败', duration: 1500 });
    }
  }

  goToCheckout() {
    let selItems: CartItem[] = [];
    this.cartItems.forEach(item => {
      if (this.selectedItems.has(item.id)) {
        selItems.push(item);
      }
    });
    router.pushUrl({
      url: 'pages/order',
      params: {
        totalPrice: this.getTotalPrice(),
        totalCount: this.selectedItems.size,
        cartItems: selItems
      }
    });
  }
}