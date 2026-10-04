import { KG_PER_LB, parseWeightInput } from '../../../lib/care/observations/weightUnits.js';

describe('weightUnits.parseWeightInput', () => {
  it('U-1 converts lb to kg for storage', () => {
    const result = parseWeightInput({ weight: 10, unit: 'lb' });
    expect(result.error).toBeUndefined();
    expect(result.kg).toBeCloseTo(10 * KG_PER_LB, 10);
  });

  it('accepts comma decimal separator', () => {
    const result = parseWeightInput({ weight: '12,4', unit: 'kg' });
    expect(result.kg).toBe(12.4);
  });

  it('U-2 rejects stone / unknown units', () => {
    const result = parseWeightInput({ weight: 10, unit: 'st' });
    expect(result).toEqual({ error: 'unit must be kg or lb' });
  });

  it('defaults missing unit to kg', () => {
    const result = parseWeightInput({ weight: 5 });
    expect(result.kg).toBe(5);
  });
});
