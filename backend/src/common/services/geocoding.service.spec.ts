import { Test, TestingModule } from '@nestjs/testing';
import { GeocodingService } from './geocoding.service';

describe('GeocodingService & Radius Math', () => {
  let service: GeocodingService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [GeocodingService],
    }).compile();

    service = module.get<GeocodingService>(GeocodingService);
  });

  it('should calculate accurate distance in meters between two lat/lng coordinates', () => {
    // Hyderabad Gachibowli to Jubilee Hills (~7.5 km)
    const meters = service.calculateDistanceMeters(17.4401, 78.3489, 17.4319, 78.4073);
    const km = meters / 1000.0;

    expect(km).toBeGreaterThan(5);
    expect(km).toBeLessThan(10);
  });

  it('should format distance correctly in meters and km', () => {
    expect(service.formatDistance(350)).toBe('350 m');
    expect(service.formatDistance(1200)).toBe('1.2 km');
    expect(service.formatDistance(4850)).toBe('4.9 km');
  });

  it('should compute bounding box enclosing radius', () => {
    const centerLat = 17.4401;
    const centerLng = 78.3489;
    const radiusKm = 10;

    const box = service.getBoundingBox(centerLat, centerLng, radiusKm);

    expect(box.minLat).toBeLessThan(centerLat);
    expect(box.maxLat).toBeGreaterThan(centerLat);
    expect(box.minLng).toBeLessThan(centerLng);
    expect(box.maxLng).toBeGreaterThan(centerLng);
  });

  it('should geocode known staging addresses deterministically', async () => {
    const res = await service.geocodeAddress('Gachibowli Stadium Road', 'Hyderabad');
    expect(res.latitude).toBeCloseTo(17.4401, 2);
    expect(res.longitude).toBeCloseTo(78.3489, 2);
  });

  it('should reverse geocode coordinates to city', async () => {
    const res = await service.reverseGeocode(17.4401, 78.3489);
    expect(res.city).toBe('Hyderabad');
  });
});
