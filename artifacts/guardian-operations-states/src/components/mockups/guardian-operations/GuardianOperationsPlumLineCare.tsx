import { useState } from 'react';
import { Bell, CalendarDays, Check, ChevronRight, CircleCheck, Heart, Home, Plus, Search, UserRound } from 'lucide-react';

const asset = (name: string) =>
  `${import.meta.env.BASE_URL}guardian-snapshot/${name}`;
type State = 'today' | 'pets' | 'care' | 'fostering' | 'vets';

const pets = [
  { name: 'Bailey', breed: 'Golden Retriever · 4 yrs', image: asset('bailey.jpg') },
  { name: 'Luna', breed: 'Domestic Shorthair · 3 yrs', image: asset('luna.jpg') },
];

function EmptyTreatment({ state, onBack, onState }: { state: Exclude<State, 'today'>; onBack: () => void; onState: (state: Exclude<State, 'today'>) => void }) {
  const content = {
    pets: ['No pets yet', 'Your care circle starts with one small profile.', asset('empty-pets.png'), 'Add a pet'],
    care: ['A clear day ahead', 'Care reminders will appear here when they are ready.', asset('empty-care.png'), 'Add care item'],
    fostering: ['No fostering sessions', 'When a shelter invites you in, sessions will live here.', asset('empty-fostering.png'), 'Explore shelters'],
    vets: ['Find your care team', 'Your trusted veterinary contacts will have a home here.', asset('empty-vets.png'), 'Add a vet'],
  }[state];
  return <div className="phone-reveal px-5 pb-28 pt-10 text-center">
    <div className="mb-8 flex justify-center gap-1.5">
      {(['pets', 'care', 'fostering', 'vets'] as const).map((item) => <button key={item} onClick={() => onState(item)} className={`rounded-full px-2.5 py-1.5 text-[9px] font-bold capitalize ${item === state ? 'bg-[#6e2e61] text-white' : 'bg-white text-[#806f79]'}`}>{item}</button>)}
    </div>
    <p className="mb-2 text-[10px] font-bold uppercase tracking-[.18em] text-[#80506f]">A quiet corner</p>
    <h2 className="font-serif text-[32px] leading-none text-[#3b2237]">{content[0]}</h2>
    <p className="mx-auto mt-3 max-w-[270px] text-[13px] leading-5 text-[#756870]">{content[1]}</p>
    <div className="mx-auto mt-8 grid h-40 w-48 place-items-center rounded-[32px] bg-[#f8e9ee]">
      <img src={content[2]} alt="" className="h-32 w-40 object-contain" />
    </div>
    <button onClick={() => alert(`${content[3]} is ready to begin`)} className="mt-8 inline-flex h-12 items-center gap-2 rounded-2xl bg-[#6e2e61] px-5 text-[13px] font-bold text-white shadow-[0_8px_18px_rgba(92,37,80,.18)]"><Plus size={16}/>{content[3]}</button>
    <button onClick={onBack} className="mt-4 block w-full text-[12px] font-semibold text-[#6e2e61]">Back to Today</button>
  </div>;
}

export function GuardianOperationsPlumLineCare() {
  const [state, setState] = useState<State>('today');
  const [done, setDone] = useState<number[]>([]);
  const [notice, setNotice] = useState('');
  const announce = (msg: string) => { setNotice(msg); window.setTimeout(() => setNotice(''), 2200); };
  const toggle = (id: number) => { setDone((items) => items.includes(id) ? items.filter((x) => x !== id) : [...items, id]); announce('Care item updated'); };
  return <main className="min-h-[100dvh] bg-[#f4f2ed] font-sans text-[#332434]">
    <div className="mx-auto w-full max-w-[430px] overflow-hidden bg-[#f4f2ed] shadow-[0_0_50px_rgba(72,38,64,.08)]">
      <header className="flex h-[78px] items-center justify-between bg-[#632653] px-5 text-[#fffaf7]">
        <div className="flex items-center gap-2"><img src={asset('logov3.png')} className="h-9 w-9 object-contain" alt="AgathaTrack"/><span className="text-[15px] font-semibold tracking-tight">AgathaTrack</span></div>
        <div className="flex items-center gap-3"><button onClick={() => announce('You are all caught up')} aria-label="Notifications"><Bell size={19}/></button><div className="grid h-8 w-8 place-items-center rounded-full bg-[#ead9e5] text-[11px] font-bold text-[#632653]">AR</div></div>
      </header>
      {state !== 'today' ? <EmptyTreatment state={state} onBack={() => setState('today')} onState={(next) => setState(next)} /> : <div className="phone-reveal space-y-3 px-4 pb-24 pt-4">
        <div className="flex items-end justify-between px-1"><div><p className="text-[10px] font-bold uppercase tracking-[.16em] text-[#826c79]">Tuesday · 14 May</p><h1 className="mt-1 font-serif text-[30px] leading-none text-[#392135]">A gentle day.</h1></div><span className="rounded-full bg-[#d9eee9] px-3 py-1.5 text-[10px] font-bold text-[#176d69]">2 of 4 done</span></div>
        <section><div className="mb-2 flex items-center justify-between px-1"><h2 className="text-[16px] font-bold">My pets</h2><button onClick={() => setState('pets')} className="text-[11px] font-bold text-[#6e2e61]">View all <ChevronRight size={13} className="inline"/></button></div><div className="grid grid-cols-[1fr_1fr_54px] gap-2">
          {pets.map((pet, i) => <button key={pet.name} onClick={() => announce(`${pet.name} selected`)} className="min-h-[88px] rounded-2xl border border-[#e6dedc] bg-white p-2 text-left shadow-[0_2px_5px_rgba(75,40,65,.04)]"><img src={pet.image} alt="" className="mx-auto h-11 w-11 rounded-full border-2 border-[#ead8d0] bg-[#eadfd9] object-cover"/><strong className="mt-1 block text-center text-[12px]">{pet.name}</strong><span className="flex items-center justify-center gap-1 text-[9px] text-[#43816f]"><CircleCheck size={11}/> {i ? 'All caught up' : 'Doing well'}</span></button>)}
          <button onClick={() => announce('Add pet flow opened')} className="grid min-h-[88px] place-items-center rounded-2xl border border-dashed border-[#c6a9bf] bg-[#faf4f8] text-[#6e2e61]"><span className="grid h-8 w-8 place-items-center rounded-full bg-[#6e2e61] text-white"><Plus size={18}/></span><span className="text-[10px] font-bold">Add pet</span></button>
        </div></section>
        <section className="overflow-hidden rounded-[22px] border border-[#6e2e61] bg-[#f4f2ed] shadow-[inset_0_0_0_1px_rgba(110,46,97,.08)]"><div className="flex items-center justify-between border-b border-[#b89aad] px-4 py-3"><div><p className="text-[10px] font-bold uppercase tracking-[.14em] text-[#6e2e61]">Care</p><h2 className="text-[16px] font-bold">Due this week <span className="ml-1 rounded-full bg-[#753463] px-2 py-0.5 text-[10px] text-white">3</span></h2></div><button onClick={() => setState('care')} className="text-[11px] font-semibold text-[#6e2e61]">View all <ChevronRight size={13} className="inline"/></button></div>
          {[['Bailey','Heartworm Preventive','Due today'],['Luna','Rabies Vaccine','Due in 3 days'],['Bailey','Nail Trim','2 days overdue']].map((row, i) => <div key={i} className="flex items-center gap-3 border-b border-[#d3c3cd] px-4 py-3"><div className="grid h-9 w-9 place-items-center rounded-xl border border-[#d7c5d2] bg-[#f8f5f1] text-[#7c5474]">{i === 2 ? <Heart size={17}/> : <CalendarDays size={17}/>}</div><div className="min-w-0 flex-1"><p className="text-[12px] font-bold">{row[0]}</p><p className="text-[11px] text-[#6f626b]">{row[1]}</p><p className={`text-[10px] ${i === 2 ? 'text-[#bd4f5a]' : 'text-[#756972]'}`}>{row[2]}</p></div><button onClick={() => toggle(i)} className={`rounded-xl px-3 py-2 text-[10px] font-bold ${done.includes(i) ? 'bg-[#2c807b] text-white' : 'bg-[#763463] text-white'}`}>{done.includes(i) ? <Check size={14}/> : 'Mark done'}</button><ChevronRight size={15} className="text-[#6e2e61]"/></div>)}
          <button onClick={() => announce('Care item flow opened')} className="flex w-full items-center justify-center gap-2 py-3 text-[11px] font-bold text-[#6e2e61]"><Plus size={15}/> Add care item</button>
        </section>
        <section className="rounded-2xl border border-[#e2dcd8] bg-white px-4 py-3"><div className="flex items-center gap-3"><div className="grid h-9 w-9 place-items-center rounded-full bg-[#d7eeea] text-[#217c76]"><Search size={16}/></div><div className="flex-1"><p className="text-[12px] font-bold">Lakeside Animal Hospital</p><p className="text-[10px] text-[#756972]">Primary care · 2.4 mi away</p></div><button onClick={() => announce('Add vet flow opened')} className="text-[11px] font-bold text-[#6e2e61]"><Plus size={16} className="inline"/> Add vet</button></div></section>
        <section className="rounded-[22px] bg-[#eaf4f2] p-4"><div className="mb-3 flex items-center justify-between"><h2 className="text-[15px] font-bold text-[#205b59]">Fostering sessions</h2><button onClick={() => setState('fostering')} className="text-[11px] font-bold text-[#267c77]">View all <ChevronRight size={13} className="inline"/></button></div><div className="space-y-2 rounded-2xl bg-white/80 p-3"><div className="flex items-center gap-3 border-b border-[#dbe9e7] pb-2"><img src={pets[0].image} alt="" className="h-10 w-10 rounded-full object-cover"/><div className="flex-1"><p className="text-[12px] font-bold">Miso</p><p className="text-[10px] text-[#6c7776]">Paws & Hope Animal Rescue</p></div><span className="rounded-full bg-[#d8eee9] px-2 py-1 text-[9px] font-bold text-[#247b75]">Active</span><ChevronRight size={14}/></div><div className="flex items-center gap-3"><img src={pets[1].image} alt="" className="h-10 w-10 rounded-full object-cover"/><div className="flex-1"><p className="text-[12px] font-bold">Luna</p><p className="text-[10px] text-[#6c7776]">Happy Tails Shelter</p></div><span className="rounded-full bg-[#d8eee9] px-2 py-1 text-[9px] font-bold text-[#247b75]">Active</span><ChevronRight size={14}/></div></div></section>
      </div>}
      <nav className="fixed bottom-0 left-1/2 z-10 flex h-[70px] w-full max-w-[430px] -translate-x-1/2 items-center justify-around bg-[#632653] px-2 text-[#f9eef7]"><button onClick={() => setState('today')} className="flex flex-col items-center gap-1 text-[10px] font-bold"><Home size={19}/>Today</button><button onClick={() => setState('pets')} className="flex flex-col items-center gap-1 text-[10px]"><UserRound size={19}/>Pets</button><button onClick={() => setState('care')} className="flex flex-col items-center gap-1 text-[10px]"><CalendarDays size={19}/>Care</button><button onClick={() => setState('fostering')} className="flex flex-col items-center gap-1 text-[10px]"><Heart size={19}/>Fostering</button></nav>
    </div>
    {notice && <div role="status" className="fixed bottom-20 left-1/2 z-20 -translate-x-1/2 rounded-xl bg-[#3b2237] px-4 py-3 text-[12px] font-semibold text-white shadow-xl">{notice}</div>}
  </main>;
}

export default GuardianOperationsPlumLineCare;