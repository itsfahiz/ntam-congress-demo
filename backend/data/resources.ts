/** Mirrors the app's illustrative Resource catalogue for grounded AI lookup. */
export type ResourceRecord = {
  id: string; title: string; kind: 'pdf' | 'slides' | 'video';
  summary: string; availability: string;
};
export const resources: ResourceRecord[] = [
  { id: 'programme', title: 'Congress Scientific Programme', kind: 'pdf',
    summary: 'On-device outline of the full congress schedule, session times, locations and speakers.',
    availability: 'Original assessment-demo PDF, generated on-device and available through the Android Save/Share chooser.' },
  { id: 'pediatric-guide', title: 'Pediatric Nutrition Guide', kind: 'pdf',
    summary: 'Illustrative clinical reference talking points for Future of Pediatric Nutrition by Dr. Sarah Johnson.',
    availability: 'Original assessment-demo PDF discussion prompts, generated on-device and available through the device Save/Share chooser.' },
  { id: 'keynote-slides', title: 'Keynote Presentation Slides', kind: 'slides',
    summary: 'Illustrative outline of the opening ceremony, welcome, pediatric nutrition and closing keynote.',
    availability: 'Original assessment-demo slide deck distributed as PDF, available through the device Save/Share chooser.' },
  { id: 'session-recap', title: 'Day 1 Session Recap', kind: 'video',
    summary: 'Illustrative recap text for Day 1 congress sessions.',
    availability: 'Original short assessment-demo MP4 title-card video, available for playback and Save/Share. Not actual congress footage.' },
];
