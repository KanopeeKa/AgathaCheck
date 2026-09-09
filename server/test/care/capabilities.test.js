import { CareFamilyCapabilityPolicy, CAPABILITY_MATRIX } from '../../lib/care/capabilities.js';
import { CARE_FAMILIES } from '../../lib/care/enums.js';

describe('CareFamilyCapabilityPolicy', () => {
  it('defines capabilities for every canonical care family', () => {
    for (const family of CARE_FAMILIES) {
      expect(CareFamilyCapabilityPolicy.getCapabilities(family)).toBeDefined();
      expect(CAPABILITY_MATRIX[family]).toBeDefined();
    }
  });

  it('only weight_monitoring supports V1 establishment and milestones', () => {
    const established = [...CARE_FAMILIES].filter(
      (family) => CareFamilyCapabilityPolicy.supportsEstablishment(family),
    );
    const milestones = [...CARE_FAMILIES].filter(
      (family) => CareFamilyCapabilityPolicy.supportsMilestones(family),
    );
    expect(established).toEqual(['weight_monitoring']);
    expect(milestones).toEqual(['weight_monitoring']);
  });

  it('weight monitoring supports dog and cat species', () => {
    expect(CareFamilyCapabilityPolicy.speciesSupportsFamily('weight_monitoring', 'Dog')).toBe(true);
    expect(CareFamilyCapabilityPolicy.speciesSupportsFamily('weight_monitoring', 'cat')).toBe(true);
    expect(CareFamilyCapabilityPolicy.speciesSupportsFamily('weight_monitoring', 'Rabbit')).toBe(false);
  });

  it('other family does not support establishment by default', () => {
    const caps = CareFamilyCapabilityPolicy.getCapabilities('other');
    expect(caps.supportsEstablishment).toBe(false);
    expect(caps.supportsMilestones).toBe(false);
    expect(caps.supportsObservations).toBe(false);
  });

  it('exposes progression read when any family supports milestones', () => {
    expect(CareFamilyCapabilityPolicy.supportsProgressionRead()).toBe(true);
  });
});
