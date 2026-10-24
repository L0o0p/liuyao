import type { Metadata } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";
import { siteConfig } from "./siteConfig";

const jakarta = Plus_Jakarta_Sans({
  variable: "--font-jakarta",
  subsets: ["latin"],
  weight: ["500", "600", "700", "800"],
});

export const metadata: Metadata = {
  metadataBase: new URL(`https://${siteConfig.siteHost}`),
  title: {
    default: `${siteConfig.productName} | 官方网站`,
    template: `%s | ${siteConfig.productName}`,
  },
  description:
    "六爻入门速记官方站点。按章节记住天干地支、五行生克、刑冲合害、十二长生和六十四卦。学习数据只留在本机。",
  icons: {
    icon: "/favicon.png",
    apple: "/apple-icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN">
      <body className={`${jakarta.variable} antialiased`}>{children}</body>
    </html>
  );
}
