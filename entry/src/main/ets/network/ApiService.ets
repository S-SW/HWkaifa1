import http from '@ohos.net.http';
import hilog from '@ohos.hilog';
import { Dish, CartItem, Order, User, Address, Banner } from '../model/Entities';
// 确保引入了你用来存取 Token 的 AppStorage 工具类
import AppStorage from '../utils/AppStorage';

const BASE_URL = 'http://10.60.62.39:8080';
const TIMEOUT = 30000;
const TAG = 'ApiService';

interface ApiResponse<T> {
  data?: T;
  code?: number;
  success?: boolean;
}

interface HttpHeader {
  'Content-Type': string;
  'Authorization'?: string;
}


interface CartAddRequest {
  dishId: number;
  quantity: number;
}

interface CartUpdateRequest {
  id: number;
  quantity: number;
}

interface LoginRequest {
  username: string;
  password: string;
}

interface AddressRequest {
  id?: number;
  userId?: number;
  contactName: string;
  contactPhone: string;
  detailAddress: string;
  isDefault: boolean | number; // 👈 扩充类型，兼容后端可能的 Integer 0/1 或 Boolean 映射
}

interface OrderCreateRequest {
  addressId: number;
  canteenId?: number;
  remark?: string;
  items: CartItem[];
}


export class ApiService {
  private static instance: ApiService;
  private token: string = '';

  static getInstance(): ApiService {
    if (!ApiService.instance) {
      ApiService.instance = new ApiService();
    }
    return ApiService.instance;
  }

  setToken(token: string) {
    this.token = token;
  }

  getToken(): string {
    return this.token;
  }

  private createHttp(): http.HttpRequest {
    let httpRequest = http.createHttp();
    return httpRequest;
  }

  private async request<T>(method: http.RequestMethod, url: string, data?: Object): Promise<T> {
    let httpRequest = this.createHttp();

    // 👇 核心修复：重新开软件时内存中 this.token 为空，主动从本地持久化缓存捞取 Token 补上
    if (!this.token) {
      try {
        let savedToken = await AppStorage.getToken();
        if (savedToken) {
          this.token = savedToken;
        }
      } catch (e) {
        hilog.error(0x0000, TAG, '从AppStorage恢复Token失败: %{public}s', JSON.stringify(e));
      }
    }

    let header: HttpHeader = {
      'Content-Type': 'application/json',
      'Authorization': this.token ? 'Bearer ' + this.token : undefined
    };

    let bodyStr = data ? JSON.stringify(data) : '';
    let fullUrl = BASE_URL + url;
    hilog.info(0x0000, TAG, '========== 请求开始 ==========');
    hilog.info(0x0000, TAG, '完整URL: %{public}s', fullUrl);
    hilog.info(0x0000, TAG, '请求方法: %{public}s', method);
    hilog.info(0x0000, TAG, '请求头: %{public}s', JSON.stringify(header));
    hilog.info(0x0000, TAG, '请求体: %{public}s', bodyStr);
    hilog.info(0x0000, TAG, '超时时间: %{public}d ms', TIMEOUT);

    let options: http.HttpRequestOptions = {
      method: method,
      header: header,
      extraData: bodyStr || undefined,
      connectTimeout: TIMEOUT,
      readTimeout: TIMEOUT
    };

    return new Promise((resolve, reject) => {
      httpRequest.request(fullUrl, options, (err: object | undefined, result: http.HttpResponse) => {
        if (err) {
          hilog.error(0x0000, TAG, '请求失败! URL: %{public}s', fullUrl);
          hilog.error(0x0000, TAG, '错误信息: %{public}s', JSON.stringify(err));
          reject(err);
          return;
        }
        hilog.info(0x0000, TAG, '响应状态码: %{public}d', result.responseCode);
        hilog.info(0x0000, TAG, '响应结果: %{public}s', result.result as string);
        hilog.info(0x0000, TAG, '========== 请求结束 ==========');
        if (result.responseCode === 200) {
          try {
            let data: T = JSON.parse(result.result as string) as T;
            resolve(data);
          } catch (e) {
            resolve(result.result as T);
          }
        } else {
          // 记录详细的错误响应
          hilog.error(0x0000, TAG, '请求失败 - 状态码: %{public}d, 响应内容: %{public}s',
            result.responseCode, result.result as string);
          reject(new Error(`Request failed with code: ${result.responseCode}, message: ${result.result}`));
        }
      });
    });
  }

  async get<T>(url: string): Promise<T> {
    return this.request<T>(http.RequestMethod.GET, url);
  }

  async post<T>(url: string, data?: CartAddRequest | CartUpdateRequest | OrderCreateRequest | LoginRequest | AddressRequest): Promise<T> {
    return this.request<T>(http.RequestMethod.POST, url, data as Object);
  }

  async put<T>(url: string, data?: CartAddRequest | CartUpdateRequest | OrderCreateRequest | AddressRequest): Promise<T> {
    return this.request<T>(http.RequestMethod.PUT, url, data as Object);
  }

  async delete<T>(url: string): Promise<T> {
    return this.request<T>(http.RequestMethod.DELETE, url);
  }

  async getDishList(): Promise<Dish[]> {
    let result = await this.get<ApiResponse<Dish[]>>('/dish/list');
    return result.data || [];
  }

  async getDishById(id: number): Promise<Dish> {
    let result = await this.get<ApiResponse<Dish>>('/dish/' + id);
    return result.data || new Dish();
  }

  async getCartList(): Promise<CartItem[]> {
    let result = await this.get<ApiResponse<CartItem[]>>('/cart/list');
    return result.data || [];
  }

  async addToCart(dishId: number, quantity: number): Promise<boolean> {
    hilog.info(0x0000, TAG, '添加购物车 - dishId: %{public}d, quantity: %{public}d', dishId, quantity);
    let body: CartAddRequest = { dishId, quantity };
    let result = await this.post<ApiResponse<null>>('/cart/add', body);
    hilog.info(0x0000, TAG, '添加购物车响应: %{public}s', JSON.stringify(result));
    return result.code === 0 || result.code === 200 || result.success === true;
  }

  async updateCartItem(id: number, quantity: number): Promise<boolean> {
    let body: CartUpdateRequest = { id, quantity };
    let result = await this.put<ApiResponse<null>>('/cart/update', body);
    return result.code === 0 || result.code === 200 || result.success === true;
  }

  async removeFromCart(id: number): Promise<boolean> {
    let result = await this.delete<ApiResponse<null>>('/cart/remove?id=' + id);
    return result.code === 0 || result.code === 200 || result.success === true;
  }

  async createOrder(addressId: number, items: CartItem[], remark?: string, canteenId?: number): Promise<Order> {
    let body: OrderCreateRequest = {
      addressId,
      items,
      remark: remark || '',
      canteenId: canteenId || 0
    };
    let result = await this.post<ApiResponse<Order>>('/order/create', body);
    return new Order(result.data);
  }

  async getOrderById(id: number): Promise<Order> {
    let result = await this.get<ApiResponse<Order>>('/order/' + id);
    return new Order(result.data) || new Order();
  }

  async getOrderList(page: number = 1, pageSize: number = 10): Promise<Order[]> {
    let result = await this.get<ApiResponse<Order[]>>('/order/list?page=' + page + '&pageSize=' + pageSize);
    return result.data || [];
  }

  // ApiService.ets 中的 cancelOrder 方法修改建议
  async cancelOrder(orderId: number): Promise<boolean> {
    hilog.info(0x0000, TAG, '取消订单请求 - orderId: %{public}d', orderId);

    // 尝试改为 post，因为很多后端接口的取消逻辑只对 POST 开放
    // 如果还是报错，请确认后端代码中是否定义为 @PostMapping("/cancel/{id}")
    let result = await this.post<ApiResponse<null>>('/order/cancel/' + orderId);

    hilog.info(0x0000, TAG, '取消订单响应: %{public}s', JSON.stringify(result));
    return result.code === 0 || result.code === 200 || result.success === true;
  }

  async login(username: string, password: string): Promise<User> {
    hilog.info(0x0000, TAG, '登录请求 - 用户名: %{public}s', username);
    let body: LoginRequest = { username, password };
    let result = await this.post<ApiResponse<User>>('/user/login', body);
    hilog.info(0x0000, TAG, '登录响应: %{public}s', JSON.stringify(result));
    if (result.data && result.data.token) {
      this.setToken(result.data.token);
    }
    return result.data || new User();
  }

  async getUserInfo(): Promise<User> {
    hilog.info(0x0000, TAG, '获取用户信息请求');
    let result = await this.get<ApiResponse<User>>('/user/info');
    hilog.info(0x0000, TAG, '获取用户信息响应: %{public}s', JSON.stringify(result));
    return result.data || new User();
  }

  async logout(): Promise<boolean> {
    let result = await this.post<ApiResponse<null>>('/user/logout');
    this.token = '';
    return result.code === 0 || result.success === true;
  }

  async getAddressList(): Promise<Address[]> {
    let result = await this.get<ApiResponse<Address[]>>('/address/list');
    return result.data || [];
  }

  async addAddress(address: Address): Promise<boolean> {
    let body: AddressRequest = {
      contactName: address.contactName,
      contactPhone: address.contactPhone,
      detailAddress: address.detailAddress, // 之前我们修正好的字段
      isDefault: address.isDefault ? 1 : 0
    };
    let result = await this.post<ApiResponse<null>>('/address/add', body);

    // 👈 核心修复：允许状态码为 0 或 200，或者 success 为 true 都算作成功
    return result.code === 0 || result.code === 200 || result.success === true;
  }

  async updateAddress(address: Address): Promise<boolean> {
    let body: AddressRequest = {
      id: address.id,
      userId: address.userId,
      contactName: address.contactName,
      contactPhone: address.contactPhone,
      detailAddress: address.detailAddress, // 之前我们修正好的字段
      isDefault: address.isDefault ? 1 : 0
    };
    let result = await this.put<ApiResponse<null>>('/address/update', body);

    // 👈 核心修复：允许状态码为 0 或 200，或者 success 为 true 都算作成功
    return result.code === 0 || result.code === 200 || result.success === true;
  }



  async deleteAddress(id: number): Promise<boolean> {
    let result = await this.delete<ApiResponse<null>>('/address/' + id);
    return result.code === 0 || result.success === true;
  }

  async getBannerList(): Promise<Banner[]> {
    let result = await this.get<ApiResponse<Banner[]>>('/banner/list');
    return result.data || [];
  }

}



export default ApiService.getInstance();

