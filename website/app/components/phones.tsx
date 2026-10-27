function PhoneFrame({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <figure className="mx-auto w-full max-w-[300px]">
      <div className="rounded-[36px] border-[7px] border-[#5c381e] bg-[#eef6ea] p-2 shadow-[0_24px_50px_rgba(92,56,30,0.16)]">
        <div className="overflow-hidden rounded-[26px] bg-[#e8f3e3]">
          <div className="flex justify-center pt-2">
            <div className="h-1.5 w-16 rounded-full bg-[#7b4e2d]/25" />
          </div>
          <div className="px-3 pb-3 pt-3">{children}</div>
        </div>
      </div>
      <figcaption className="mt-3 text-center text-[11px] font-semibold tracking-[0.18em] text-[#7a5a47]">
        {label} · 界面示意
      </figcaption>
    </figure>
  );
}

function MiniNav({ active }: { active: "今日" | "章节" | "我的" }) {
  const items = ["今日", "章节", "我的"] as const;
  return (
    <div className="mt-3 flex items-center justify-around rounded-full border border-[#7b4e2d]/20 bg-[#fffdf7] px-2 py-1.5">
      {items.map((item) => (
        <span
          key={item}
          className={
            item === active
              ? "rounded-full bg-[#cdebc5] px-3 py-1 text-[10px] font-bold text-[#082009] shadow-[0_2px_0_#5c381e]"
              : "px-3 py-1 text-[10px] font-semibold text-[#83746b]"
          }
        >
          {item}
        </span>
      ))}
    </div>
  );
}

export function TodayPhone() {
  return (
    <PhoneFrame label="今日">
      <div className="flex items-center justify-between">
        <p className="text-lg font-extrabold text-[#603718]">今日学习</p>
        <span className="rounded-full border border-[#7b4e2d] bg-[#fffdf7] px-2 py-0.5 text-[10px] font-bold text-[#603718]">
          连续 6 天
        </span>
      </div>
      <div className="mt-3 grid grid-cols-2 gap-2">
        <div className="biscuit rounded-2xl px-2 py-3 text-center">
          <p className="text-[10px] font-bold text-[#7b4e2d]">待温故</p>
          <p className="mt-1 text-3xl font-extrabold leading-none text-[#603718]">
            12
          </p>
          <p className="mt-1 text-[10px] font-semibold text-[#51443c]">到期复习</p>
        </div>
        <div className="biscuit rounded-2xl px-2 py-3 text-center">
          <p className="text-[10px] font-bold text-[#4b6548]">新知识</p>
          <p className="mt-1 text-3xl font-extrabold leading-none text-[#4b6548]">
            10
          </p>
          <p className="mt-1 text-[10px] font-semibold text-[#51443c]">今天新学</p>
        </div>
      </div>
      <p className="mt-2 text-center text-[11px] font-semibold text-[#51443c]">
        今天新学：天干五行（10 条）
      </p>
      <div className="tactile-btn mt-3 rounded-full py-2.5 text-center text-sm font-extrabold">
        开始
      </div>
      <MiniNav active="今日" />
    </PhoneFrame>
  );
}

const chapters = [
  { index: "1", title: "五行生克", hint: "木生火，火生土", width: "100%" },
  { index: "2", title: "天干", hint: "甲乙东方木", width: "46%" },
  { index: "3", title: "地支", hint: "寅卯木，巳午火", width: "12%" },
  { index: "4", title: "刑冲合害", hint: "六合、三合、六冲", width: "0%" },
];

export function ChapterPhone() {
  return (
    <PhoneFrame label="章节">
      <p className="text-lg font-extrabold text-[#603718]">章节</p>
      <p className="mt-1 text-[11px] leading-5 text-[#51443c]">
        对照表、口诀和掌握进度，按学习顺序排好。
      </p>
      <div className="mt-3 space-y-2">
        {chapters.map((chapter) => (
          <div key={chapter.title} className="biscuit rounded-2xl px-3 py-2">
            <div className="flex items-center gap-2">
              <span className="flex h-6 w-6 items-center justify-center rounded-full border border-[#7b4e2d] bg-[#cdebc5] text-[11px] font-extrabold text-[#603718]">
                {chapter.index}
              </span>
              <div>
                <p className="text-sm font-extrabold text-[#603718]">{chapter.title}</p>
                <p className="text-[10px] text-[#83746b]">{chapter.hint}</p>
              </div>
            </div>
            <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-[#e6e2d8]">
              <div
                className="h-full rounded-full bg-[#7ac471]"
                style={{ width: chapter.width }}
              />
            </div>
          </div>
        ))}
      </div>
      <MiniNav active="章节" />
    </PhoneFrame>
  );
}

export function QuizPhone() {
  const options = ["木", "火", "土", "金"] as const;

  return (
    <PhoneFrame label="练习">
      <div className="flex items-center justify-between text-[11px] font-bold text-[#603718]">
        <span>天干五行</span>
        <span className="rounded-full border border-[#7b4e2d]/30 bg-[#fffdf7] px-2 py-0.5">
          查表
        </span>
      </div>
      <p className="mt-1 text-[10px] font-semibold text-[#83746b]">3 / 10</p>
      <div className="biscuit mt-3 rounded-2xl px-3 py-4">
        <p className="text-[10px] font-bold tracking-[0.2em] text-[#b87c14]">答题</p>
        <p className="mt-2 text-xl font-extrabold text-[#603718]">寅的五行是？</p>
      </div>
      <div className="mt-3 grid grid-cols-2 gap-2">
        {options.map((option) => (
          <div
            key={option}
            className="rounded-2xl border-2 border-[#7b4e2d] bg-[#fffdf7] py-3 text-center text-base font-extrabold text-[#603718] shadow-[0_3px_0_#5c381e]"
          >
            {option}
          </div>
        ))}
      </div>
      <p className="mt-3 text-[10px] leading-5 text-[#51443c]">
        答错会留下讲解。十二长生会按「日支五行 → 长生起点 → 顺数到爻支」写出步骤。
      </p>
    </PhoneFrame>
  );
}

export function MinePhone() {
  return (
    <PhoneFrame label="我的">
      <p className="text-lg font-extrabold text-[#603718]">我的</p>
      <div className="biscuit mt-3 rounded-2xl p-3">
        <p className="text-[11px] font-bold text-[#7b4e2d]">连续学习</p>
        <p className="mt-1 text-3xl font-extrabold leading-none text-[#603718]">
          6 <span className="text-sm">天</span>
        </p>
      </div>
      <div className="mt-2 grid grid-cols-3 gap-1.5">
        <Stat label="已掌握" value="54" className="bg-[#ecf9ea] text-[#234221] border-[#548050]" />
        <Stat label="学习中" value="37" className="bg-[#fff5db] text-[#523504] border-[#b87c14]" />
        <Stat label="未学" value="291" className="bg-[#f1eee3] text-[#51443c] border-[#83746b]" />
      </div>
      <div className="mt-3 space-y-2">
        <div className="rounded-full border-2 border-[#7b4e2d] bg-[#fffdf7] py-2 text-center text-[12px] font-extrabold text-[#603718] shadow-[0_3px_0_#7b4e2d]">
          导出学习数据
        </div>
        <div className="rounded-full border-2 border-[#7b4e2d] bg-[#fdf9ee] py-2 text-center text-[12px] font-extrabold text-[#603718] shadow-[0_3px_0_#7b4e2d]">
          导入学习数据
        </div>
      </div>
      <MiniNav active="我的" />
    </PhoneFrame>
  );
}

function Stat({
  label,
  value,
  className,
}: {
  label: string;
  value: string;
  className: string;
}) {
  return (
    <div className={`rounded-xl border-2 px-1 py-2 text-center ${className}`}>
      <p className="text-[9px] font-bold">{label}</p>
      <p className="text-lg font-extrabold leading-none">{value}</p>
    </div>
  );
}
