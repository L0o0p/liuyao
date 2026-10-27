import Image from "next/image";
import Link from "next/link";
import {
  ChapterPhone,
  MinePhone,
  QuizPhone,
  TodayPhone,
} from "./components/phones";
import { siteConfig } from "./siteConfig";

const tiles = [
  { char: "甲", meta: "阳木", tone: "bg-[#bbf7d0] text-[#14532d]" },
  { char: "丙", meta: "阳火", tone: "bg-[#fecaca] text-[#991b1b]" },
  { char: "戊", meta: "阳土", tone: "bg-[#fed7aa] text-[#7c2d12]" },
  { char: "庚", meta: "阳金", tone: "bg-[#fef08a] text-[#854d0e]" },
  { char: "壬", meta: "阳水", tone: "bg-[#bfdbfe] text-[#1e3a8a]" },
  { char: "寅", meta: "木", tone: "bg-[#bbf7d0] text-[#14532d]" },
  { char: "午", meta: "火", tone: "bg-[#fecaca] text-[#991b1b]" },
  { char: "申", meta: "金", tone: "bg-[#fef08a] text-[#854d0e]" },
  { char: "子", meta: "水", tone: "bg-[#bfdbfe] text-[#1e3a8a]" },
  { char: "乾", meta: "☰", tone: "bg-[#fef08a] text-[#854d0e]" },
  { char: "坎", meta: "☵", tone: "bg-[#bfdbfe] text-[#1e3a8a]" },
  { char: "离", meta: "☲", tone: "bg-[#fecaca] text-[#991b1b]" },
  { char: "六合", meta: "子丑", tone: "bg-[#fffdf7] text-[#603718]" },
  { char: "六冲", meta: "子午", tone: "bg-[#fffdf7] text-[#603718]" },
  { char: "长生", meta: "在亥", tone: "bg-[#cdebc5] text-[#234221]" },
  { char: "木生", meta: "火", tone: "bg-[#bbf7d0] text-[#14532d]" },
];

const highlights = [
  {
    title: "今日该练什么",
    body: "打开就能看见到期复习和今天新学的一组。先把到期的做完，再引入今天这一组。全部做完之后，还可以再学一组。",
    phone: <TodayPhone />,
  },
  {
    title: "六章按顺序排好",
    body: "五行生克、天干、地支、刑冲合害、十二长生、六十四卦。每章有对照表、口诀和掌握进度，也可以只练这一章。",
    phone: <ChapterPhone />,
  },
  {
    title: "先看表，再逐条练",
    body: "新的一组先给出整组对照和口诀，然后逐条出题。答对就继续；答错会标出正确答案。十二长生会按步骤写出推算过程。做题时可以随时查表。",
    phone: <QuizPhone />,
  },
  {
    title: "进度只留在手机里",
    body: "没有账号，也不上传。学习记录可以导出成 JSON，换机时再导入。合并时较新的记录保留，不会用旧备份盖掉新进度。",
    phone: <MinePhone />,
  },
];

const modules = [
  "今日复习",
  "每天一组",
  "五行生克",
  "天干地支",
  "刑冲合害",
  "十二长生",
  "六十四卦",
  "对照查表",
  "答错讲解",
  "连续打卡",
  "导入导出",
  "本机存储",
];

const notes = [
  {
    title: "382 条",
    body: "天干地支属性、刑冲合害、十二长生规则和六十四卦，拆成固定对应关系来记。",
  },
  {
    title: "33 组",
    body: "每章再分成小组。今天默认引入一组，先看整组，再逐条考。",
  },
  {
    title: "间隔拉开",
    body: "答错很快再出现。答对且够快，间隔会拉长。间隔不少于 21 天，记为已掌握。",
  },
];

export default function Home() {
  return (
    <main className="min-h-screen overflow-hidden text-[#1c1c15]">
      <header className="fixed left-0 right-0 top-0 z-50 border-b border-[#7b4e2d]/15 bg-[#fdf9ee]/82 backdrop-blur-xl">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-5 sm:px-8">
          <Link href="/" className="flex items-center gap-3">
            <Image
              src="/liuyao-logo.png"
              alt="六爻入门速记"
              width={36}
              height={36}
              className="rounded-lg"
              priority
            />
            <span className="text-sm font-extrabold tracking-[0.22em] text-[#603718]">
              六爻
            </span>
          </Link>
          <nav className="hidden items-center gap-8 text-xs font-bold text-[#7a5a47] md:flex">
            <a href="#today" className="transition hover:text-[#603718]">
              今日
            </a>
            <a href="#features" className="transition hover:text-[#603718]">
              功能
            </a>
            <a href="#modules" className="transition hover:text-[#603718]">
              章节
            </a>
            <a href="#contact" className="transition hover:text-[#603718]">
              联系
            </a>
            <Link href="/privacy-policy" className="transition hover:text-[#603718]">
              隐私政策
            </Link>
          </nav>
          <a href="#contact" className="tactile-btn rounded-full px-5 py-2 text-xs font-extrabold">
            联系作者
          </a>
        </div>
      </header>

      <section className="relative flex min-h-[760px] items-center justify-center px-5 pb-24 pt-28 sm:min-h-[880px]">
        <div className="pointer-events-none absolute inset-0 opacity-70" aria-hidden>
          <div className="absolute left-1/2 top-0 grid w-[1180px] -translate-x-1/2 -rotate-6 grid-cols-8 gap-3 sm:w-[1460px]">
            {[...tiles, ...tiles].map((tile, index) => (
              <div
                key={`${tile.char}-${index}`}
                className={`flex aspect-[4/5] flex-col items-center justify-center rounded-2xl border-2 border-[#7b4e2d] shadow-[0_4px_0_rgba(123,78,45,0.18)] ${tile.tone}`}
              >
                <span className="text-3xl font-extrabold">{tile.char}</span>
                <span className="mt-2 text-[11px] font-bold opacity-80">{tile.meta}</span>
              </div>
            ))}
          </div>
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_18%,rgba(254,203,77,0.28),transparent_26%),linear-gradient(180deg,rgba(229,242,224,0.2),#e5f2e0_82%)]" />
        </div>

        <div className="relative z-10 mx-auto max-w-4xl text-center">
          <div className="mx-auto mb-8 flex h-28 w-28 items-center justify-center rounded-full border-2 border-[#7b4e2d] bg-[#fffdf7] shadow-[0_8px_0_rgba(123,78,45,0.16)]">
            <Image
              src="/liuyao-logo.png"
              alt=""
              width={84}
              height={84}
              className="rounded-2xl"
              priority
            />
          </div>
          <p className="mb-5 text-xs font-extrabold uppercase tracking-[0.42em] text-[#7b4e2d]">
            Liuyao Official
          </p>
          <h1 className="mx-auto max-w-3xl text-4xl font-extrabold leading-tight tracking-tight text-[#603718] sm:text-6xl">
            每天几分钟
            <br />
            把六爻基础记熟
          </h1>
          <p className="mx-auto mt-6 max-w-2xl text-sm leading-8 text-[#51443c] sm:text-base">
            {siteConfig.productName}把天干地支、五行生克、刑冲合害、十二长生和六十四卦拆成 382
            条对应关系。先看一组对照表，再按间隔重复练到会。学习记录只留在你的手机里。
          </p>
          <div className="mt-10 flex flex-wrap items-center justify-center gap-3">
            <a href="#features" className="tactile-btn rounded-full px-7 py-3 text-sm font-extrabold">
              查看功能
            </a>
            <Link
              href="/user-agreement"
              className="rounded-full border-2 border-[#7b4e2d] bg-[#fffdf7]/80 px-7 py-3 text-sm font-extrabold text-[#603718] shadow-[0_4px_0_#7b4e2d] transition hover:translate-y-0.5 hover:shadow-[0_2px_0_#7b4e2d]"
            >
              用户协议
            </Link>
          </div>
        </div>
      </section>

      <section className="relative -mt-20 border-y border-[#7b4e2d]/20 bg-[#fdf9ee] py-8">
        <div className="mx-auto grid max-w-6xl grid-cols-4 gap-2 px-5 sm:px-8 md:grid-cols-8">
          {tiles.slice(0, 8).map((tile) => (
            <div
              key={tile.char}
              className={`flex aspect-[3/4] flex-col items-center justify-center rounded-2xl border-2 border-[#7b4e2d] shadow-[0_6px_0_rgba(123,78,45,0.12)] ${tile.tone}`}
            >
              <span className="text-2xl font-extrabold sm:text-3xl">{tile.char}</span>
              <span className="mt-2 text-[11px] font-bold">{tile.meta}</span>
            </div>
          ))}
        </div>
      </section>

      <section
        id="today"
        className="relative overflow-hidden border-b border-[#7b4e2d]/15 bg-[#d7ebcf] px-5 py-24 sm:px-8"
      >
        <div className="relative mx-auto grid max-w-6xl items-center gap-12 lg:grid-cols-[0.9fr_1.1fr]">
          <TodayPhone />
          <div>
            <p className="text-xs font-extrabold uppercase tracking-[0.42em] text-[#4b6548]">
              Today
            </p>
            <h2 className="mt-5 max-w-xl text-3xl font-extrabold leading-tight text-[#603718] sm:text-5xl">
              今天复习多少，新学哪一组
            </h2>
            <p className="mt-5 max-w-2xl text-sm leading-8 text-[#51443c] sm:text-base">
              适合每天几分钟。到期的卡片排在前面，今天的新组跟在后面。一组先看整表和口诀，再逐条练习。
              当天引入过的小组不会重复推送。
            </p>
            <div className="mt-10 grid gap-4 sm:grid-cols-3">
              {notes.map((note) => (
                <article key={note.title} className="biscuit rounded-2xl p-4">
                  <h3 className="text-xl font-extrabold text-[#603718]">{note.title}</h3>
                  <p className="mt-2 text-xs leading-6 text-[#7a5a47]">{note.body}</p>
                </article>
              ))}
            </div>
          </div>
        </div>
      </section>

      <section id="features" className="relative mx-auto max-w-6xl px-5 py-24 sm:px-8 sm:py-32">
        <div className="space-y-24">
          {highlights.map((item, index) => (
            <article
              key={item.title}
              className={`grid items-center gap-10 md:grid-cols-2 ${
                index % 2 === 1 ? "md:[&>*:first-child]:order-2" : ""
              }`}
            >
              <div>{item.phone}</div>
              <div className="mx-auto max-w-md text-center md:text-left">
                <p className="mb-4 text-xs font-extrabold uppercase tracking-[0.32em] text-[#7b4e2d]">
                  0{index + 1}
                </p>
                <h2 className="text-3xl font-extrabold text-[#603718] sm:text-5xl">{item.title}</h2>
                <p className="mt-5 text-sm leading-8 text-[#51443c] sm:text-base">{item.body}</p>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section
        id="modules"
        className="relative border-y border-[#7b4e2d]/15 bg-[#fdf9ee] px-5 py-28 sm:px-8"
      >
        <div className="mx-auto max-w-4xl text-center">
          <p className="text-xs font-extrabold uppercase tracking-[0.42em] text-[#7b4e2d]">
            Six Chapters
          </p>
          <h2 className="mt-5 text-3xl font-extrabold text-[#603718] sm:text-5xl">
            记的是对应关系，不是玄学结论
          </h2>
          <p className="mx-auto mt-5 max-w-2xl text-sm leading-8 text-[#51443c]">
            从五行生到六十四卦，按一条学习顺序往下走。这是记忆工具，不起卦，也不替你做判断。
          </p>
          <div className="mx-auto mt-12 grid max-w-2xl grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
            {modules.map((module) => (
              <div key={module} className="biscuit min-h-24 rounded-2xl p-4 text-left">
                <div className="mb-4 h-1.5 w-10 rounded-full bg-[#fecb4d]" />
                <p className="text-sm font-extrabold text-[#603718]">{module}</p>
                <p className="mt-2 text-[11px] leading-5 text-[#9b7a67]">本机学习</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section
        id="contact"
        className="relative mx-auto flex min-h-[560px] max-w-5xl flex-col items-center justify-center px-5 py-24 text-center sm:px-8"
      >
        <div className="biscuit flex items-center gap-3 rounded-2xl px-4 py-3">
          <Image src="/liuyao-logo.png" alt="" width={36} height={36} className="rounded-lg" />
          <span className="text-lg font-extrabold tracking-[0.18em] text-[#603718]">六爻</span>
        </div>
        <h2 className="mt-12 text-3xl font-extrabold text-[#603718] sm:text-5xl">
          把基础对应关系留在手头
        </h2>
        <p className="mx-auto mt-5 max-w-xl text-sm leading-8 text-[#51443c]">
          官方网站：{siteConfig.siteHost}。反馈、备案和合作请发邮件。
        </p>
        <a
          href={`mailto:${siteConfig.contactEmail}`}
          className="tactile-btn mt-9 rounded-full px-8 py-3 text-sm font-extrabold"
        >
          {siteConfig.contactEmail}
        </a>
      </section>

      <footer className="border-t border-[#7b4e2d]/20 bg-[#fdf9ee] px-5 py-10 text-center text-xs leading-7 text-[#7a5a47] sm:px-8">
        <div className="mx-auto flex max-w-5xl flex-wrap items-center justify-center gap-x-6 gap-y-2">
          <Link href="/user-agreement" className="font-bold hover:text-[#603718]">
            用户协议
          </Link>
          <Link href="/privacy-policy" className="font-bold hover:text-[#603718]">
            隐私政策
          </Link>
          <span>版权所有者：{siteConfig.ownerName}</span>
          <span>网站备案信息：{siteConfig.icpRecordNumber}</span>
        </div>
        <p className="mt-4">
          Copyright © {new Date().getFullYear()} {siteConfig.ownerName}. All Rights Reserved.
        </p>
      </footer>
    </main>
  );
}
