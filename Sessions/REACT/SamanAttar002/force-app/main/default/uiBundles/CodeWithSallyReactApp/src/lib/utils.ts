import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/**
 * Decode HTML entities in a string (e.g. "Tom &amp; Jerry" → "Tom & Jerry").
 *
 * Salesforce's UI API returns string field values HTML-encoded, but React renders
 * text literally (it never decodes entities), so values like `&amp;` show up raw.
 * The textarea trick lets the browser's parser decode entities for us; textarea is an
 * RCDATA element, so tags inside the input are treated as text and never executed.
 */
export function decodeHtmlEntities(value: string | null | undefined): string {
  if (!value) return '';
  const el = document.createElement('textarea');
  el.innerHTML = value;
  return el.value;
}
