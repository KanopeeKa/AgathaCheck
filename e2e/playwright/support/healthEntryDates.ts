/** Matches Flutter `formatHealthEntryStatusDate` (`DateFormat('dd MMM yy')`). */
export function formatHealthEntryStatusDate(isoDate: string): string {
  const [year, month, day] = isoDate.split('-').map((part) => Number(part));
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  const dd = String(day).padStart(2, '0');
  const yy = String(year).slice(-2);
  return `${dd} ${months[month - 1]} ${yy}`;
}
