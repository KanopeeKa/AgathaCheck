import img_cinematic_portrait_1 from './images/cinematic-portrait-1.jpg';
import img_landscape_1 from './images/landscape-1.jpg';
import img_street_1 from './images/street-1.jpg';
import img_architecture_1 from './images/architecture-1.jpg';
import img_hands_1 from './images/hands-1.jpg';
import img_abstract_1 from './images/abstract-1.jpg';
import img_candid_1 from './images/candid-1.jpg';
import img_tree_1 from './images/tree-1.jpg';
import img_vintage_car_1 from './images/vintage-car-1.jpg';
import img_still_life_1 from './images/still-life-1.jpg';
import img_about_headshot from './images/about-headshot.png';
import img_about_interior from './images/about-interior.png';
import img_about_ocean from './images/about-ocean.png';
import img_featured_breakfast from './images/featured-breakfast.jpg';
import img_street_warm from './images/street-warm.jpg';
import React, { useEffect, useState, useMemo } from 'react';
import { motion, useScroll, useTransform, AnimatePresence } from 'framer-motion';
import { ArrowRight, ArrowUpRight, Camera, Mail, MapPin } from 'lucide-react';

const IMAGES = [
  img_cinematic_portrait_1,
  img_landscape_1,
  img_street_1,
  img_architecture_1,
  img_hands_1,
  img_abstract_1,
  img_candid_1,
  img_tree_1,
  img_vintage_car_1,
  img_still_life_1,
  img_about_headshot,
  img_about_interior,
  img_about_ocean,
  img_featured_breakfast,
  img_street_warm, // 14
];

// Generate deterministic scattered positions for the floating gallery
function generateFloatingCards() {
  const HARDCODED_LAYOUT = [
    // Inner ring (12 cards, strictly spaced, ~50-70px)
    { x: 50, y: 16, size: 50 },
    { x: 67, y: 17, size: 55 },
    { x: 81, y: 32, size: 65 },
    { x: 83, y: 50, size: 70 },
    { x: 81, y: 68, size: 65 },
    { x: 67, y: 83, size: 60 },
    { x: 50, y: 84, size: 55 },
    { x: 33, y: 83, size: 60 },
    { x: 19, y: 68, size: 65 },
    { x: 17, y: 50, size: 70 },
    { x: 19, y: 32, size: 65 },
    { x: 33, y: 17, size: 55 },

    // Outer ring (12 cards, strictly spaced, ~75-105px)
    { x: 88, y: 19, size: 75 },
    { x: 94, y: 35, size: 95 },
    { x: 96, y: 55, size: 105 },
    { x: 94, y: 75, size: 95 },
    { x: 84, y: 91, size: 85 },
    { x: 64, y: 97, size: 85 },
    { x: 36, y: 97, size: 85 },
    { x: 16, y: 91, size: 85 },
    { x: 6, y: 75, size: 95 },
    { x: 4, y: 55, size: 105 },
    { x: 6, y: 35, size: 95 },
    { x: 12, y: 19, size: 75 }
  ];

  return HARDCODED_LAYOUT.map((pos, i) => {
    // Alternate rotation ± signs between 4° and 8°
    const rotMagnitude = 4 + (i % 5); 
    const rotation = (i % 2 === 0) ? rotMagnitude : -rotMagnitude;
    const driftRot = (i % 2 === 0) ? -1.5 : 1.5; // Very tiny rot drift

    return {
      id: i,
      src: IMAGES[i % IMAGES.length],
      x: pos.x,
      y: pos.y,
      size: pos.size,
      rotation,
      delay: (i % 6) * 0.5,
      duration: 15 + (i % 10),
      // Handpick a few cards to have subtle depth blur
      blur: [3, 7, 14, 18, 22].includes(i) ? 2 : 0, 
      opacity: 0.92 + (i % 3) * 0.04,
      zIndex: i,
      driftRot
    };
  });
}

function TopNav() {
  const [isScrolled, setIsScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 40);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <nav 
      className={`fixed top-0 left-0 right-0 z-[100] px-6 flex items-center justify-between pointer-events-auto transition-all duration-300 ${
        isScrolled 
          ? "bg-[#FDFBF7]/90 backdrop-blur-md border-b border-black/5 text-black shadow-sm py-4" 
          : "mix-blend-difference text-white py-6"
      }`}
    >
      <div className="flex items-center gap-2">
        <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold tracking-tighter transition-colors duration-300 ${
          isScrolled ? "bg-black text-white" : "bg-white text-black"
        }`}>
          AM
        </div>
        <span className="font-medium text-sm tracking-tight hidden sm:block">Alex Mitchell</span>
      </div>
      
      <div className="hidden md:flex items-center gap-8 text-sm font-medium">
        <a href="#work" className="hover:opacity-70 transition-opacity">Work</a>
        <a href="#about" className="hover:opacity-70 transition-opacity">About</a>
        <a href="#journal" className="hover:opacity-70 transition-opacity">Journal</a>
      </div>
      
      <div className="flex items-center gap-4">
        <button className={`px-4 py-2 rounded-full text-sm font-medium transition-colors duration-300 ${
          isScrolled ? "bg-black text-white hover:bg-gray-800" : "bg-white text-black hover:bg-gray-200"
        }`}>
          Get in touch
        </button>
      </div>
    </nav>
  );
}

function FloatingCard({ card, scrollYProgress }: { card: any, scrollYProgress: any }) {
  // Parallax effect based on z-index (larger z-index moves faster)
  const yOffset = useTransform(scrollYProgress, [0, 1], [0, -card.zIndex * 25]);

  return (
    <motion.div
      className="absolute rounded-xl overflow-hidden shadow-[0_4px_16px_rgb(0,0,0,0.06)] border border-white/40 bg-white"
      style={{
        left: `calc(${card.x}% - ${card.size / 2}px)`,
        top: `calc(${card.y}% - ${(card.size * 1.25) / 2}px)`,
        width: card.size,
        height: card.size * 1.25, // 4:5 aspect ratio
        zIndex: card.zIndex,
        filter: card.blur > 0 ? `blur(${card.blur}px)` : 'none',
        opacity: card.opacity,
        y: yOffset,
      }}
      initial={{ opacity: 0 }}
      animate={{ 
        y: [0, -4, 0], 
        rotate: [card.rotation, card.rotation + card.driftRot, card.rotation],
        opacity: card.opacity
      }}
      transition={{
        y: {
          duration: card.duration,
          repeat: Infinity,
          ease: "easeInOut",
          delay: card.delay,
        },
        rotate: {
          duration: card.duration * 1.2,
          repeat: Infinity,
          ease: "easeInOut",
          delay: card.delay,
        },
        opacity: { duration: 0.15 }
      }}
      whileHover={{
        scale: 1.05,
        zIndex: 50,
        filter: 'blur(0px)',
        opacity: 1,
        transition: { duration: 0.3 }
      }}
    >
      <img 
        src={card.src} 
        alt="" 
        className="w-full h-full object-cover"
        loading="lazy"
      />
    </motion.div>
  );
}

export default function FloatingGallery() {
  const [mounted, setMounted] = useState(false);
  const { scrollYProgress } = useScroll();
  const opacity = useTransform(scrollYProgress, [0, 0.2], [1, 0]);
  const scale = useTransform(scrollYProgress, [0, 0.2], [1, 0.95]);

  const cards = useMemo(() => generateFloatingCards(), []);

  useEffect(() => {
    setMounted(true);
  }, []);

  return (
    <div className="min-h-screen bg-[#FDFBF7] text-[#111] font-sans selection:bg-black selection:text-white overflow-x-hidden">
      <TopNav />
      
      {/* Hero Section */}
      <section className="relative h-[120vh] w-full overflow-hidden flex flex-col items-center justify-center pt-20">
        {/* Gradient fade at bottom to transition to content */}
        <div className="absolute bottom-0 left-0 right-0 h-64 bg-gradient-to-t from-[#FDFBF7] to-transparent z-40 pointer-events-none" />
        
        {/* Floating Cards Background */}
        <div 
          className="absolute inset-0 z-0 pointer-events-auto overflow-hidden"
          style={{ 
            maskImage: 'linear-gradient(to bottom, black 0%, black 60%, transparent 100%)', 
            WebkitMaskImage: 'linear-gradient(to bottom, black 0%, black 60%, transparent 100%)' 
          }}
        >
          {mounted && cards.map((card) => (
            <FloatingCard key={card.id} card={card} scrollYProgress={scrollYProgress} />
          ))}
        </div>

        {/* Hero Content */}
        <motion.div 
          className="relative z-[60] flex flex-col items-center text-center px-6 max-w-4xl mx-auto pointer-events-none mt-[-10vh]"
          style={{ opacity, scale }}
        >
          <motion.h1 
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2, delay: 0.05 }}
            className="text-6xl sm:text-7xl md:text-8xl lg:text-[7rem] font-medium tracking-tight leading-[0.9] text-black"
          >
            Capturing life<br />in motion.
          </motion.h1>

          <motion.p 
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2, delay: 0.1 }}
            className="mt-8 text-lg sm:text-xl text-gray-500 max-w-xl mx-auto font-medium"
          >
            I document human connection and quiet moments, turning fleeting seconds into timeless memories.
          </motion.p>

          <motion.div 
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2, delay: 0.15 }}
            className="mt-10 flex flex-col sm:flex-row items-center gap-4 pointer-events-auto"
          >
            <button className="bg-black text-white px-8 py-4 rounded-full font-medium flex items-center gap-2 hover:bg-gray-800 transition-colors w-full sm:w-auto justify-center group">
              View Portfolio
              <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
            </button>
            <button className="bg-white text-black border border-gray-200 px-8 py-4 rounded-full font-medium hover:bg-gray-50 transition-colors w-full sm:w-auto justify-center shadow-sm">
              Read the Journal
            </button>
          </motion.div>
        </motion.div>
      </section>

      {/* Featured Work Section */}
      <section id="work" className="relative z-40 bg-[#FDFBF7] py-32 px-6">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center gap-3 mb-8">
            <div className="w-1.5 h-1.5 rounded-full bg-[#A39A88]/40" />
            <span className="text-[11px] font-medium tracking-[0.2em] uppercase text-[#A39A88]">
              Selected Works — 01
            </span>
          </div>
          <div className="w-full h-px bg-black/5 mb-16" />
          
          <div className="flex flex-col lg:flex-row justify-between items-start lg:items-end gap-12 mb-20">
            <h2 className="text-5xl md:text-6xl lg:text-7xl font-medium tracking-tight leading-[1.1]">
              Visual narratives <br />
              <span className="font-serif italic text-[#A39A88] font-light">& fragments.</span>
            </h2>
            <div className="max-w-md">
              <p className="text-lg text-gray-600 leading-relaxed mb-8">
                A curated collection of recent commissions spanning portraiture, landscape, and street photography. Exploring the quiet poetry of <span className="font-serif italic text-gray-400">everyday existence</span>.
              </p>
              <a href="#" className="group inline-flex items-center gap-4">
                <span className="relative text-[11px] font-medium tracking-[0.2em] uppercase text-black pb-1">
                  Explore Archive
                  <span className="absolute bottom-0 left-0 w-full h-[1px] bg-black/20" />
                  <span className="absolute bottom-0 left-0 w-full h-[1px] bg-black origin-left scale-x-0 transition-transform duration-500 ease-out group-hover:scale-x-100" />
                </span>
                <ArrowUpRight className="w-4 h-4 text-black opacity-50 group-hover:opacity-100 group-hover:translate-x-1 group-hover:-translate-y-1 transition-all duration-500 ease-out" />
              </a>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              { src: IMAGES[0], title: 'Neon Nights', category: 'Portraiture', aspect: 'aspect-[3/4]', span: 'md:col-span-1 lg:col-span-1' },
              { src: IMAGES[1], title: 'Misty Peaks', category: 'Landscape', aspect: 'aspect-[4/3]', span: 'md:col-span-1 lg:col-span-2' },
              { src: IMAGES[14], title: 'Lantern Light', category: 'Street', aspect: 'aspect-square', span: 'md:col-span-1 lg:col-span-1' },
              { src: IMAGES[3], title: 'Concrete Angles', category: 'Architecture', aspect: 'aspect-[3/4]', span: 'md:col-span-1 lg:col-span-1' },
              { src: IMAGES[4], title: 'The Artisan', category: 'Documentary', aspect: 'aspect-square', span: 'md:col-span-1 lg:col-span-1' },
            ].map((item, i) => (
              <motion.div 
                key={i}
                initial={{ opacity: 0, y: 15 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-50px" }}
                transition={{ duration: 0.2, delay: i * 0.05 }}
                className={`group cursor-pointer ${item.span}`}
              >
                <div className={`relative overflow-hidden rounded-2xl bg-gray-100 ${item.aspect} mb-4`}>
                  <img 
                    src={item.src} 
                    alt={item.title} 
                    className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105" 
                  />
                  <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors duration-500" />
                </div>
                <div className="flex justify-between items-start mt-2">
                  <div>
                    <h3 className="text-xl font-serif italic text-gray-900 tracking-wide">{item.title}</h3>
                    <p className="text-[10px] font-medium tracking-[0.2em] uppercase text-[#A39A88] mt-1.5">{item.category}</p>
                  </div>
                  <div className="w-8 h-8 rounded-full border border-black/10 flex items-center justify-center opacity-0 -translate-x-2 group-hover:opacity-100 group-hover:translate-x-0 transition-all duration-500 ease-out">
                    <ArrowUpRight className="w-4 h-4 text-black/60" />
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* About Section */}
      <section id="about" className="py-32 px-6 bg-white border-y border-gray-100">
        <div className="max-w-7xl mx-auto flex flex-col lg:flex-row gap-16 items-center">
          <div className="w-full lg:w-1/2 relative">
            <div className="aspect-[4/5] rounded-3xl overflow-hidden">
              <img src={IMAGES[10]} alt="Alex Mitchell" className="w-full h-full object-cover" />
            </div>
            <div className="absolute -bottom-8 -right-8 w-48 h-48 rounded-2xl overflow-hidden border-8 border-white shadow-xl hidden md:block rotate-6">
              <img src={IMAGES[13]} alt="Behind the scenes" className="w-full h-full object-cover" />
            </div>
          </div>
          
          <div className="w-full lg:w-1/2 flex flex-col justify-center">
            <h2 className="text-4xl md:text-5xl font-medium tracking-tight mb-8">
              Finding the extraordinary in the mundane.
            </h2>
            <div className="space-y-6 text-lg text-gray-600">
              <p>
                I'm Alex, a photographer based in San Francisco. For the past decade, I've been chasing light and shadows across the globe.
              </p>
              <p>
                My work is driven by a desire to capture genuine emotion and the unspoken stories that unfold around us every day. Whether shooting a bustling street market in Tokyo or a quiet misty morning in the Cascades, my approach remains the same: observe patiently, act decisively.
              </p>
              <p>
                When I'm not behind the lens, you can find me exploring coastal trails, hunting for vintage vinyl, or experimenting with new coffee brewing methods.
              </p>
            </div>
            
            <div className="mt-12 flex items-center gap-6">
              <div className="flex items-center gap-2 text-sm font-medium">
                <MapPin className="w-4 h-4 text-gray-400" />
                San Francisco, CA
              </div>
              <div className="flex items-center gap-2 text-sm font-medium">
                <Mail className="w-4 h-4 text-gray-400" />
                Available for travel
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="relative bg-[#1A1918] text-[#E8E3D9] py-32 px-6 overflow-hidden">
        {/* Subtle noise/grain texture overlay */}
        <div className="absolute inset-0 opacity-[0.03] pointer-events-none" style={{ backgroundImage: 'url("data:image/svg+xml,%3Csvg viewBox=\'0 0 200 200\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cfilter id=\'noiseFilter\'%3E%3CfeTurbulence type=\'fractalNoise\' baseFrequency=\'0.85\' numOctaves=\'3\' stitchTiles=\'stitch\'/%3E%3C/filter%3E%3Crect width=\'100%25\' height=\'100%25\' filter=\'url(%23noiseFilter)\'/%3E%3C/svg%3E")' }} />

        <div className="max-w-7xl mx-auto relative z-10">
          <div className="flex flex-col lg:flex-row justify-between items-end gap-16 mb-32">
            <div className="max-w-2xl">
              <h2 className="text-5xl md:text-7xl font-medium tracking-tight mb-16 leading-[1.1]">
                Let's create something <br />
                <span className="font-serif italic text-[#D4C8B5] font-light">timeless.</span>
              </h2>

              <a href="mailto:hello@alexmitchell.com" className="group inline-flex items-center gap-6">
                <span className="relative text-2xl md:text-4xl lg:text-5xl tracking-tight pb-2">
                  hello@alexmitchell.com
                  <span className="absolute bottom-0 left-0 w-full h-[2px] bg-[#D4C8B5]/20" />
                  <span className="absolute bottom-0 left-0 w-full h-[2px] bg-[#D4C8B5] origin-left scale-x-0 transition-transform duration-500 ease-out group-hover:scale-x-100" />
                </span>
                <ArrowUpRight className="w-8 h-8 md:w-10 md:h-10 text-[#D4C8B5] opacity-50 group-hover:opacity-100 group-hover:translate-x-2 group-hover:-translate-y-2 transition-all duration-500 ease-out" />
              </a>
            </div>
          </div>
          
          <div className="w-full h-px bg-white/10 mb-8" />
          
          <div className="w-full flex flex-col md:flex-row justify-between items-center gap-6 text-[11px] font-medium tracking-[0.15em] uppercase text-[#A39A88]">
            <div>&copy; 2026 Alex Mitchell. All rights reserved.</div>
            <div className="flex gap-8">
              <a href="#" className="hover:text-[#E8E3D9] transition-colors">Instagram</a>
              <a href="#" className="hover:text-[#E8E3D9] transition-colors">Twitter</a>
              <a href="#" className="hover:text-[#E8E3D9] transition-colors">Behance</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
