import router from '@ohos.router';
import AppStorage from './AppStorage';

export class AuthGuard {
  private static instance: AuthGuard;
  private redirectUrl: string = 'pages/home';

  static getInstance(): AuthGuard {
    if (!AuthGuard.instance) {
      AuthGuard.instance = new AuthGuard();
    }
    return AuthGuard.instance;
  }

  setRedirectUrl(url: string) {
    this.redirectUrl = url;
  }

  getRedirectUrl(): string {
    return this.redirectUrl;
  }

  async isLoggedIn(): Promise<boolean> {
    try {
      const token = await AppStorage.getToken();
      const userInfo = await AppStorage.getUserInfo();
      return !!token && !!userInfo && !!userInfo.userId;
    } catch (e) {
      return false;
    }
  }

  async checkAuthAndRedirect(redirectUrl: string = 'pages/home'): Promise<boolean> {
    const loggedIn = await this.isLoggedIn();
    if (!loggedIn) {
      this.setRedirectUrl(redirectUrl);
      router.pushUrl({
        url: 'pages/login'
      });
      return false;
    }
    return true;
  }

  async navigateAfterLogin() {
    const url = this.getRedirectUrl();
    this.setRedirectUrl('pages/home');
    router.replaceUrl({
      url: url
    });
  }
}

export default AuthGuard.getInstance();