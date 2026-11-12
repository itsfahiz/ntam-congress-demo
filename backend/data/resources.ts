/** Mirrors the app's illustrative Resource catalogue for grounded AI lookup. */
export type ResourceRecord = {
  id: string; title: string; kind: 'pdf' | 'slides' | 'video';
  summary: string; availability: string;
};
export const resources: ResourceRecord[] = [
  { id: 'programme', title: 'Congress Scientific Programme', kind: 'pdf',
    summary: 'On-device outline of the full congress schedule, session times, locations and speakers.',
    availability: 'On-device summary only; no downloadable PDF is included.' },
  { id: 'pediatric-guide', title: 'Pediatric Nutrition Guide', kind: 'pdf',
    summary: 'Illustrative clinical reference talking points for Future of Pediatric Nutrition by Dr. Sarah Johnson.',
    availability: 'On-device summary only; no downloadable PDF is included.' },
  { id: 'keynote-slides', title: 'Keynote Presentation Slides', kind: 'slides',
    summary: 'Illustrative outline of the opening ceremony, welcome, pediatric nutrition and closing keynote.',
    availability: 'On-device slide outline only; no presentation file is included.' },
  { id: 'session-recap', title: 'Day 1 Session Recap', kind: 'video',
    summary: 'Illustrative recap text for Day 1 congress sessions.',
    availability: 'Preview only; no video file is included.' },
];
