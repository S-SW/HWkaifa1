export class Dish {
  id: number = 0;
  canteenId: number = 0;
  name: string = '';
  description: string = '';
  price: number = 0;
  originalPrice: number | null = null;
  imageUrl: string = '';
  image: string = '';
  category: string = '';
  taste: string = '';
  rating: number | null = null;
  monthlySales: number | null = null;
  stock: number | null = null;
  isAvailable: boolean | null = null;
  status: number = 1;
  createdAt: string = '';
  updatedAt: string = '';

  constructor(data?: object) {
    if (data) {
      this.id = (data as Dish).id || 0;
      this.canteenId = (data as Dish).canteenId || 0;
      this.name = (data as Dish).name || '';
      this.description = (data as Dish).description || '';
      this.price = (data as Dish).price || 0;
      this.originalPrice = (data as Dish).originalPrice || null;
      this.imageUrl = (data as Dish).imageUrl || '';
      this.image = (data as Dish).image || '';
      this.category = (data as Dish).category || '';
      this.taste = (data as Dish).taste || '';
      this.rating = (data as Dish).rating || null;
      this.monthlySales = (data as Dish).monthlySales || null;
      this.stock = (data as Dish).stock || null;
      this.isAvailable = (data as Dish).isAvailable || null;
      this.status = (data as Dish).status || 1;
      this.createdAt = (data as Dish).createdAt || '';
      this.updatedAt = (data as Dish).updatedAt || '';
    }
  }
}

export class CartItem {
  id: number = 0;
  userId: number = 0;
  dishId: number = 0;
  quantity: number = 1;
  createdAt: string = '';
  updatedAt: string = '';
  dish: Dish = new Dish();

  constructor(data?: object) {
    if (data) {
      this.id = (data as CartItem).id || 0;
      this.userId = (data as CartItem).userId || 0;
      this.dishId = (data as CartItem).dishId || 0;
      this.quantity = (data as CartItem).quantity || 1;
      this.createdAt = (data as CartItem).createdAt || '';
      this.updatedAt = (data as CartItem).updatedAt || '';
      if ((data as CartItem).dish) {
        this.dish = new Dish((data as CartItem).dish as object);
      }
    }
  }

  get dishName(): string {
    return this.dish.name;
  }

  get price(): number {
    return this.dish.price;
  }

  get image(): string {
    return this.dish.imageUrl;
  }
}

export class Order {
  /** 订单ID */
  id: number = 0;
  /** 订单号 */
  orderNo: string = '';
  /** 用户ID */
  userId: number = 0;
  /** 食堂ID */
  canteenId: number = 0;
  /** 总金额 */
  totalAmount: number = 0;
  /** 菜品金额 */
  dishAmount: number = 0;
  /** 配送费 */
  deliveryAmount: number = 0;
  /** 订单状态：1-待支付 2-待接单 3-待配送 4-配送中 5-已完成 6-已取消 */
  status: number = 0;
  /** 支付状态：0-未支付 1-已支付 */
  payStatus: number = 0;
  /** 支付时间 */
  payTime?: string = '';
  /** 地址ID */
  addressId: number = 0;
  /** 备注 */
  remark?: string = '';
  /** 取消原因 */
  cancelReason?: string = '';
  /** 预计送达时间 */
  estimatedDeliveryTime?: string = '';
  /** 实际送达时间 */
  deliveryTime?: string = '';
  /** 创建时间 */
  createdAt: string = '';
  /** 更新时间 */
  updatedAt: string = '';
  /** 订单明细 */
  items: OrderItem[] = [];
  /** 收货地址 */
  address?: Address;

  constructor(data?: object) {
    if (data) {
      this.id = (data as Order).id || 0;
      this.orderNo = (data as Order).orderNo || '';
      this.userId = (data as Order).userId || 0;
      this.canteenId = (data as Order).canteenId || 0;
      this.totalAmount = (data as Order).totalAmount || 0;
      this.dishAmount = (data as Order).dishAmount || 0;
      this.deliveryAmount = (data as Order).deliveryAmount || 0;
      this.status = (data as Order).status || 0;
      this.payStatus = (data as Order).payStatus || 0;
      this.payTime = (data as Order).payTime || '';
      this.addressId = (data as Order).addressId || 0;
      this.remark = (data as Order).remark || '';
      this.cancelReason = (data as Order).cancelReason || '';
      this.estimatedDeliveryTime = (data as Order).estimatedDeliveryTime || '';
      this.deliveryTime = (data as Order).deliveryTime || '';
      this.createdAt = (data as Order).createdAt || '';
      this.updatedAt = (data as Order).updatedAt || '';

      if ((data as Order).items) {
        this.items = (data as Order).items.map(item => new OrderItem(item as object));
      }

      if ((data as Order).address) {
        this.address = new Address((data as Order).address as object);
      }
    }
  }
}

export class OrderItem {
  /** 订单明细ID */
  id: number = 0;
  /** 订单ID */
  orderId: number = 0;
  /** 菜品ID */
  dishId: number = 0;
  /** 菜品名称 */
  dishName: string = '';
  /** 菜品图片 */
  imageUrl?: string = '';
  /** 单价 */
  price: number = 0;
  /** 数量 */
  quantity: number = 0;
  /** 小计 */
  subtotal: number = 0;

  constructor(data?: object) {
    if (data) {
      this.id = (data as OrderItem).id || 0;
      this.orderId = (data as OrderItem).orderId || 0;
      this.dishId = (data as OrderItem).dishId || 0;
      this.dishName = (data as OrderItem).dishName || '';
      this.imageUrl = (data as OrderItem).imageUrl || '';
      this.price = (data as OrderItem).price || 0;
      this.quantity = (data as OrderItem).quantity || 0;
      this.subtotal = (data as OrderItem).subtotal || 0;
    }
  }
}

export class User {
  userId: number = 0;
  username: string = '';
  phone: string = '';
  nickname: string = '';
  token: string = '';
  avatarUrl: string = '';

  constructor(data?: object) {
    if (data) {
      this.userId = (data as User).userId || 0;
      this.username = (data as User).username || '';
      this.phone = (data as User).phone || '';
      this.nickname = (data as User).nickname || '';
      this.token = (data as User).token || '';
      this.avatarUrl = (data as User).avatarUrl || '';
    }
  }
}

export class Address {
  id: number = 0;
  userId: number = 0;
  contactName: string = '';
  contactPhone: string = '';
  detailAddress: string = '';
  isDefault: boolean = false;

  constructor(data?: object) {
    if (data) {
      this.id = (data as Address).id || 0;
      this.userId = (data as Address).userId || 0;
      this.contactName = (data as Address).contactName || '';
      this.contactPhone = (data as Address).contactPhone || '';
      this.detailAddress = (data as Address).detailAddress || '';
      this.isDefault = (data as Address).isDefault || false;
    }
  }

  toString(): string {
    return `姓名：${this.contactName}, 电话：${this.contactPhone}, 地址：${this.detailAddress}`;
  }
}

export class Banner {
  id: number = 0;
  image: string = '';
  link: string = '';
  sort: number = 0;

  constructor(data?: object) {
    if (data) {
      this.id = (data as Banner).id || 0;
      this.image = (data as Banner).image || '';
      this.link = (data as Banner).link || '';
      this.sort = (data as Banner).sort || 0;
    }
  }
}