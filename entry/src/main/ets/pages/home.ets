import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import ApiService from '../network/ApiService';
import AppStorage from '../utils/AppStorage';
import { Banner, Dish } from '../model/Entities';
import AuthGuard from '../utils/AuthGuard';

@Entry
@Component
struct Home {
  @State banners: Banner[] = [];
  @State categories: string[] = ['全部', '家常','主食', '荤菜', '素菜', '烧烤','面食','小吃'];
  @State selectedCategory: string = '全部';
  @State dishes: Dish[] = [];
  @State isLoading: boolean = false;
  @State currentBannerIndex: number = 0;
  @State cartCount: number = 0;
  @State isLoggedIn: boolean = false;

  @State localBanners: Resource[] = [
    $r('app.media.banner1'),
    $r('app.media.banner2'),
    $r('app.media.banner3')
  ];

  // ==================== 布局自适应配置面板 ====================
  // 💡 【核心修改点 1】: 在这里自由切换列数
  // 若想改为 1 列大图流：设为 1； 若想改为 3 列紧凑流：设为 3
  @State columnsCount: number = 3;

  // 💡 【核心修改点 2】: 卡片间距与图片圆角统一管理
  @State cardGaps: number = 12;       // 网格卡片之间的间距 (单位: vp)
  @State imageBorderRadius: number = 12; // 图片及卡片的圆角弧度 (单位: vp)
  // =========================================================

  async aboutToAppear() {
    this.checkLoginStatus();
    this.loadData();
  }

  aboutToDisappear() {
  }

  async onPageShow() {
    this.checkLoginStatus();
    this.loadCartCount();
  }

  async checkLoginStatus() {
    this.isLoggedIn = await AuthGuard.isLoggedIn();
  }

  async loadCartCount() {
    try {
      let cartList = await ApiService.getCartList();
      let total = 0;
      cartList.forEach(item=>{
        total += item.quantity;
      })
      this.cartCount = total;
    } catch (e) {
    }
  }

  async loadData() {
    this.isLoading = true;
    try {
      let bannerList = await ApiService.getBannerList();
      this.banners = bannerList;

      let dishList = await ApiService.getDishList();
      this.dishes = dishList;

      let cartList = await ApiService.getCartList();
      this.cartCount = cartList.length;
    } catch (e) {
      promptAction.showToast({ message: '加载数据失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  getFilteredDishes(): Dish[] {
    if (this.selectedCategory === '全部') {
      return this.dishes;
    }
    return this.dishes.filter(dish => dish.category === this.selectedCategory);
  }

  async goToOrder() {
    const loggedIn = await AuthGuard.isLoggedIn();
    if (!loggedIn) {
      AuthGuard.setRedirectUrl('pages/order');
      router.pushUrl({ url: 'pages/login' });
    } else {
      router.pushUrl({ url: 'pages/order' });
    }
  }

  async goToCart() {
    const loggedIn = await AuthGuard.isLoggedIn();
    if (!loggedIn) {
      AuthGuard.setRedirectUrl('pages/cart');
      router.pushUrl({ url: 'pages/login' });
    } else {
      router.pushUrl({ url: 'pages/cart' });
    }
  }

  build() {
    Column() {
      Row() {
        Text('食堂订餐')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.color_primary'))

        Blank()

        if (this.isLoggedIn) {
          Image($r('app.media.ic_my'))
            .width(28)
            .height(28)
            .onClick(() => {
              router.pushUrl({ url: 'pages/mine' });
            })
            .margin({ right: 15 })
        } else {
          Text('登录')
            .fontSize(16)
            .fontColor($r('app.color.color_primary'))
            .onClick(() => {
              AuthGuard.setRedirectUrl('pages/home');
              router.pushUrl({ url: 'pages/login' });
            })
            .margin({ right: 15 })
        }

        Badge({
          count: this.cartCount,
          style: { badgeSize: 16, badgeColor:  $r('app.color.color_primary')},
          position: BadgePosition.Right
        }) {
          Image($r('app.media.ic_cart'))
            .width(28)
            .height(28)
        }
        .onClick(() => {
          this.goToCart();
        })
      }
      .width('100%')
      .height(60)
      .padding({ left: 15, right: 15 })
      .backgroundColor($r('app.color.page_bg'))

      Scroll() {
        Column() {
          if (this.localBanners && this.localBanners.length > 0) {
            Swiper() {
              ForEach(this.localBanners, (imgResource: Resource) => {
                Image(imgResource)
                  .width('100%')
                  .height(180)
                  .objectFit(ImageFit.Cover)
              })
            }
            .width('100%')
            .height(180)
            .autoPlay(true)
            .interval(3000)
            .indicator(true)
            .loop(true)
            .onChange((index: number) => {
              this.currentBannerIndex = index;
            })
          } else {
            Image($r('app.media.icon'))
              .width('100%')
              .height(180)
              .objectFit(ImageFit.Cover)
          }

          Column() {
            Text('美食分类')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .padding({ left: 15, top: 15, bottom: 10 })

            Scroll() {
              Row() {
                ForEach(this.categories, (category: string) => {
                  Column() {
                    Text(category)
                      .fontSize(14)
                      .fontColor(this.selectedCategory === category ? '#FFFFFF' : '#666666')
                      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
                      .backgroundColor(this.selectedCategory === category ? $r('app.color.color_primary') : '#F5F5F5')
                      .borderRadius(20)
                  }
                  .margin({ right: 10 })
                  .onClick(() => {
                    this.selectedCategory = category;
                  })
                })
              }
              .padding({ left: 15, right: 15 })
            }
            .align(Alignment.Top)
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')

          Column() {
            Text('推荐菜品')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .padding({ left: 15, top: 15, bottom: 10 })

            // 💡 【核心修改点 3】: 动态生成网格布局模板，并绑定动态间距，适配屏幕
            Grid() {
              ForEach(this.getFilteredDishes(), (dish: Dish) => {
                GridItem() {
                  this.DishCard(dish)
                }
              })
            }
            .width('100%')
            // 根据配置的列数，自动生成 '1fr' / '1fr 1fr' / '1fr 1fr 1fr' 从而完美适配多端屏幕
            .columnsTemplate(Array(this.columnsCount).fill('1fr').join(' '))
            .columnsGap(this.cardGaps)
            .rowsGap(this.cardGaps)
            .padding({ left: 15, right: 15 })
            // 依据列数动态调整网格的整体包裹高度
            .height(this.getFilteredDishes().length > 0 ?
              Math.ceil(this.getFilteredDishes().length / this.columnsCount) * (this.columnsCount === 1 ? 260 : (this.columnsCount === 3 ? 170 : 200)) : 200)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 10 })
        }
        .width('100%')
      }
      .align(Alignment.Top)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .layoutWeight(1)

      Row() {
        this.BottomNavItem('首页', $r('app.media.ic_home'), true, () => {})

        this.BottomNavItem('订单', $r('app.media.ic_order'), false, () => {
          this.goToOrder();
        })

        Badge({
          count: this.cartCount,
          position: BadgePosition.RightTop,
          style: { badgeSize: 16, badgeColor: $r('app.color.color_primary') },
        }) {
          this.BottomNavItem('购物车', $r('app.media.ic_cart'), false, () => {
            this.goToCart();
          })
        }

        this.BottomNavItem('我的', $r('app.media.ic_my'), false, () => {
          router.pushUrl({ url: 'pages/mine' });
        })
      }
      .width('100%')
      .height(60)
      .backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.SpaceEvenly)
      .alignItems(VerticalAlign.Center)
      .shadow({
        radius: 10,
        color: '#10000000',
        offsetX: 0,
        offsetY: -2
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  DishCard(dish: Dish) {
    Column() {
      // 💡 【核心修改点 4】: 自适应图片高度，并应用动态图片圆角
      Image(dish.imageUrl || $r('app.media.icon'))
        .width('100%')
        // 根据不同列数智能调节图片展示比例：1列用大图（150），3列用小图（90）
        .height(this.columnsCount === 1 ? 160 : (this.columnsCount === 3 ? 90 : 120))
        .objectFit(ImageFit.Cover)
        .borderRadius({ topLeft: this.imageBorderRadius, topRight: this.imageBorderRadius })

      Text(dish.name)
        .fontSize(this.columnsCount === 3 ? 12 : 14) // 3列时字体适度缩小防重叠
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .padding({ left: 8, right: 8, top: 6 })

      Row() {
        Text('¥' + dish.price)
          .fontSize(this.columnsCount === 3 ? 14 : 16)
          .fontColor($r('app.color.color_primary'))
          .fontWeight(FontWeight.Bold)

        Blank()

        Image($r('app.media.ic_add'))
          .width(this.columnsCount === 3 ? 20 : 24) // 3列时按钮适度缩小
          .height(this.columnsCount === 3 ? 20 : 24)
          .fillColor($r('app.color.color_primary'))
          .onClick(() => {
            this.addToCart(dish);
          })
      }
      .width('100%')
      .padding({ left: 8, right: 8, bottom: 6, top: 2 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(this.imageBorderRadius) // 卡片整体应用新圆角
    .shadow({
      radius: 4,
      color: '#0D000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/dishDetail',
        params: { dishId: dish.id }
      });
    })
  }

  @Builder
  BottomNavItem(title: string, icon: Resource, isSelected: boolean, onClickHandler: () => void) {
    Column() {
      Image(icon)
        .width(26)
        .height(26)
        .fillColor(isSelected ? $r('app.color.color_primary') : '#999999')

      Text(title)
        .fontSize(12)
        .fontColor(isSelected ? $r('app.color.color_primary') : '#999999')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
    .onClick(onClickHandler)
  }

  async addToCart(dish: Dish) {
    const loggedIn = await AuthGuard.isLoggedIn();
    if (!loggedIn) {
      AuthGuard.setRedirectUrl('pages/home');
      router.pushUrl({ url: 'pages/login' });
      return;
    }
    try {
      let success = await ApiService.addToCart(dish.id, 1);
      if (success) {
        this.cartCount++;
        promptAction.showToast({ message: '已添加到购物车', duration: 1500 });
      }
    } catch (e) {
      promptAction.showToast({ message: '添加失败', duration: 1500 });
    }
  }
}