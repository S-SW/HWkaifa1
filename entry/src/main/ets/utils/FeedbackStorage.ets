//utils/FeedbackStorage.ets
import preferences from '@ohos.data.preferences';
import { Feedback } from '../model/Entities';

const PREFERENCES_NAME = 'canteen_feedback';

class FeedbackStorage {
  private static instance: FeedbackStorage;
  private prefs: preferences.Preferences | null = null;

  private constructor() {}

  static getInstance(): FeedbackStorage {
    if (!FeedbackStorage.instance) {
      FeedbackStorage.instance = new FeedbackStorage();
    }
    return FeedbackStorage.instance;
  }

  async init(context: Context) {
    if (!this.prefs) {
      this.prefs = await preferences.getPreferences(context, PREFERENCES_NAME);
    }
  }

  // 修正：参数类型改为 number，内部转为 string
  private getKey(userId: number): string {
    return `feedback_${userId}`;
  }

  async getFeedbacks(userId: number): Promise<Feedback[]> {
    if (!this.prefs) return [];
    const key = this.getKey(userId);
    const data = await this.prefs.get(key, '[]');
    try {
      const list = JSON.parse(data as string) as Feedback[];
      // 将普通对象转换为 Feedback 实例（可选，但推荐）
      return list.map(item => new Feedback(item));
    } catch (e) {
      return [];
    }
  }

  async addFeedback(feedback: Feedback): Promise<void> {
    if (!this.prefs) return;
    const userId = feedback.userId;
    const key = this.getKey(userId);
    const list = await this.getFeedbacks(userId);
    list.unshift(feedback); // 最新的在前
    await this.prefs.put(key, JSON.stringify(list));
    await this.prefs.flush();
  }

  async clearFeedbacks(userId: number): Promise<void> {
    if (!this.prefs) return;
    const key = this.getKey(userId);
    await this.prefs.put(key, '[]');
    await this.prefs.flush();
  }
}

export default FeedbackStorage.getInstance();