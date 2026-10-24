import type { Metadata } from "next";
import { LegalDocument } from "../components/legal-document";
import { siteConfig } from "../siteConfig";

export const metadata: Metadata = {
  title: "用户协议",
  description: "六爻入门速记的服务范围、本机数据责任和知识产权说明。",
};

export default function UserAgreementPage() {
  return (
    <LegalDocument title={`${siteConfig.productName} 用户协议`}>
      <p>
        欢迎使用 {siteConfig.productName}（下称「本应用」）。本协议由开发者 {siteConfig.ownerName} 与用户共同订立。
        下载、安装或使用本应用前，请阅读并理解本协议。一旦使用，即表示同意受其约束。
      </p>
      <p>
        1. 服务内容：本应用提供六爻基础知识的对照学习、口诀、答题练习、间隔重复和本机进度管理。
        范围包括五行生克、天干、地支、刑冲合害、十二长生和六十四卦。
        本应用是记忆工具。它不起卦，不给出占卜结论，也不构成命理、医疗、法律、投资或其他专业建议。
      </p>
      <p>
        2. 使用规范：请合法使用本应用，不要从事违法活动，也不要破坏应用的正常运行。
      </p>
      <p>
        3. 数据：本应用没有账号。学习数据保存在你的设备上。导出、保管和导入备份由你自行负责。
        卸载、清空卡片，或换机时没有备份，都可能导致进度丢失。
      </p>
      <p>
        4. 知识产权：应用的界面、图标、交互、代码和文案编排归开发者或相应权利人所有。
        天干地支、卦名等传统知识本身是公共文化内容，本协议不对其主张专有权利。
      </p>
      <p>
        5. 责任限制：本应用在本机离线运行。因设备故障、系统限制、误操作或未备份造成的数据丢失或学习中断，在法律允许的范围内，开发者不承担超出法定范围的责任。
        本网站用于产品说明，以及公示本协议和隐私政策。
      </p>
      <p>
        6. 协议变更：开发者可根据产品或法律要求更新本协议，并在本网站公示。更新后继续使用，即表示接受更新后的协议。
      </p>
      <p>
        7. 联系方式：如有问题，请联系 {siteConfig.contactEmail}。
      </p>
    </LegalDocument>
  );
}
