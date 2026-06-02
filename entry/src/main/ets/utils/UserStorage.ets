import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { User } from '../model/Entities';

const PREFERENCES_NAME = 'canteen_prefs';
const KEY_USER_TOKEN = 'user_token';
const KEY_USER_INFO = 'user_info';

export class UserStorage {
  private static instance: UserStorage;
  private context: common.UIAbilityContext | null = null;
  private prefs: dataPreferences.Preferences | null = null;

  static getInstance(): UserStorage {
    if (!UserStorage.instance) {
      UserStorage.instance = new UserStorage();
    }
    return UserStorage.instance;
  }

  async init(context: common.UIAbilityContext) {
    this.context = context;
    this.prefs = await dataPreferences.getPreferences(context, PREFERENCES_NAME);
  }

  async setToken(token: string): Promise<void> {
    if (this.prefs) {
      await this.prefs.put(KEY_USER_TOKEN, token);
      await this.prefs.flush();
    }
  }

  async getToken(): Promise<string> {
    if (this.prefs) {
      return await this.prefs.get(KEY_USER_TOKEN, '') as string;
    }
    return '';
  }

  async setUserInfo(user: User): Promise<void> {
    if (this.prefs) {
      await this.prefs.put(KEY_USER_INFO, JSON.stringify(user));
      await this.prefs.flush();
    }
  }

  async getUserInfo(): Promise<User | null> {
    if (this.prefs) {
      let userStr = await this.prefs.get(KEY_USER_INFO, '') as string;
      if (userStr) {
        return JSON.parse(userStr) as User;
      }
    }
    return null;
  }

  async clearUserInfo(): Promise<void> {
    if (this.prefs) {
      await this.prefs.delete(KEY_USER_TOKEN);
      await this.prefs.delete(KEY_USER_INFO);
      await this.prefs.flush();
    }
  }
}

export default UserStorage.getInstance();