import Link from "next/link";
import { siteConfig } from "../siteConfig";

export function LegalDocument({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <main className="mx-auto min-h-screen w-full max-w-4xl px-6 py-12 sm:px-10">
      <div className="biscuit rounded-3xl p-8 sm:p-10">
        <p className="text-xs font-extrabold tracking-[0.32em] text-[#7b4e2d]">
          LIUYAO
        </p>
        <h1 className="mt-3 text-3xl font-extrabold text-[#603718]">{title}</h1>
        <p className="mt-3 text-sm text-[#83746b]">
          更新日期：{siteConfig.policyUpdatedAt}
        </p>
        <section className="mt-6 space-y-4 text-sm leading-7 text-[#51443c]">
          {children}
        </section>
        <div className="mt-8 flex flex-wrap gap-x-6 gap-y-2 text-sm font-bold">
          <Link href="/" className="text-[#7b4e2d] underline underline-offset-4">
            返回首页
          </Link>
          <Link
            href="/user-agreement"
            className="text-[#7b4e2d] underline underline-offset-4"
          >
            用户协议
          </Link>
          <Link
            href="/privacy-policy"
            className="text-[#7b4e2d] underline underline-offset-4"
          >
            隐私政策
          </Link>
        </div>
      </div>
    </main>
  );
}
