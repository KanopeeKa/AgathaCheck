import {
  BLOCKS_BY_CARE_FAMILY,
  careBlocksForApi,
  dosageFromProductDose,
  enrichBlocksFromLegacyDosage,
  filterBlocksForFamily,
  parseCareBlocksObject,
  resolveCareBlocksForWrite,
} from '../../lib/care/categoryBlocks/index.js';

describe('categoryBlocks', () => {
  it('filters blocks by care family', () => {
    const blocks = {
      product_dose: { product_name: 'Metacam' },
      visit: { questions_to_ask: 'Annual?' },
    };
    expect(filterBlocksForFamily(blocks, 'medication')).toEqual({
      product_dose: { product_name: 'Metacam' },
    });
    expect(filterBlocksForFamily(blocks, 'vaccination')).toEqual({
      visit: { questions_to_ask: 'Annual?' },
    });
    expect(filterBlocksForFamily(blocks, 'weight_monitoring')).toEqual({});
  });

  it('maps legacy dosage into product dose on read', () => {
    const api = careBlocksForApi({
      care_family: 'medication',
      dosage: '1 tablet',
      care_blocks: {},
    });
    expect(api.product_dose.dose_amount).toBe('1 tablet');
  });

  it('syncs dosage column from product dose on write', () => {
    const { dosage, careBlocks } = resolveCareBlocksForWrite({
      data: {
        care_blocks: {
          product_dose: {
            dose_amount: '2',
            dose_unit: 'ml',
          },
        },
      },
      careFamily: 'medication',
    });
    expect(dosage).toBe('2 ml');
    expect(careBlocks.product_dose.dose_amount).toBe('2');
  });

  it('strips visit block when family changes to medication', () => {
    const { careBlocks } = resolveCareBlocksForWrite({
      data: { care_family: 'medication' },
      careFamily: 'medication',
      existing: {
        care_blocks: { visit: { questions_to_ask: 'Boosters?' } },
        dosage: '',
      },
      careFamilyChanged: true,
    });
    expect(careBlocks).toEqual({});
  });

  it('documents delivery order families include product or visit blocks', () => {
    expect(BLOCKS_BY_CARE_FAMILY.medication).toContain('product_dose');
    expect(BLOCKS_BY_CARE_FAMILY.vaccination).toContain('visit');
    expect(BLOCKS_BY_CARE_FAMILY.weight_monitoring).toEqual([]);
  });

  it('parses camelCase wire keys', () => {
    const blocks = parseCareBlocksObject({
      productDose: { product_name: 'Bravecto' },
    });
    expect(blocks.product_dose.product_name).toBe('Bravecto');
  });

  it('dosageFromProductDose falls back to legacy', () => {
    expect(dosageFromProductDose({}, '5mg')).toBe('5mg');
    expect(
      dosageFromProductDose(
        { product_dose: { dose_amount: '1', dose_unit: 'tab' } },
        '',
      ),
    ).toBe('1 tab');
  });

  it('enrichBlocksFromLegacyDosage does not overwrite explicit dose', () => {
    const enriched = enrichBlocksFromLegacyDosage(
      { product_dose: { dose_amount: '2 mg' } },
      'legacy',
    );
    expect(enriched.product_dose.dose_amount).toBe('2 mg');
  });
});
