import { Button, Input } from '@/components/ui';
import { useState } from 'react';
import { createLead } from '@/api/leads';
import {createContact} from '@/api/contacts';

type Status = 'idle' | 'submitting' | 'success' | 'error';

export default function Contact() {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');
  const [status, setStatus] = useState<Status>('idle');
  const [error, setError] = useState('');

  async function submit() {
    setStatus('submitting');
    setError('');

    try {
      await createLead({ firstName, lastName, email, message });

      setStatus('success');
      setFirstName('');
      setLastName('');
      setEmail('');
      setMessage('');
    } catch (err) {
      setStatus('error');
      setError(err instanceof Error ? err.message : 'Something went wrong.');
    }
  }

  return (
    <div className="max-w-xl mx-auto px-4 py-12">
      <h1 className="text-4xl font-bold text-gray-900 mb-2 text-center">Contact Us</h1>
      <p className="text-gray-600 text-center mb-8">
        Have a question? Drop us a note.
      </p>

      {status === 'success' ? (
        <div className="rounded-lg border border-green-200 bg-green-50 p-4 text-center text-green-800">
          Thanks! We&apos;ve received your message and will be in touch.
        </div>
      ) : (
        <form
          className="flex flex-col gap-4"
          onSubmit={(e) => {
            e.preventDefault();
            void submit();
          }}
        >
          <div className="flex gap-4">
            <div className="flex-1">
              <label htmlFor="firstName" className="block text-sm font-medium mb-1">First Name</label>
              <Input
                id="firstName"
                required
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
              />
            </div>
            <div className="flex-1">
              <label htmlFor="lastName" className="block text-sm font-medium mb-1">Last Name</label>
              <Input
                id="lastName"
                required
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
              />
            </div>
          </div>

          <div>
            <label htmlFor="email" className="block text-sm font-medium mb-1">Email</label>
            <Input
              id="email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>

          <div>
            <label htmlFor="message" className="block text-sm font-medium mb-1">Message</label>
            <textarea
              id="message"
              rows={4}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              className="w-full border rounded-lg px-2.5 py-2 text-sm"
            />
          </div>

          {status === 'error' && (
            <p className="text-sm text-red-600">{error}</p>
          )}

          <Button type="submit" disabled={status === 'submitting'}>
            {status === 'submitting' ? 'Sending…' : 'Submit'}
          </Button>
        </form>
      )}
    </div>
  );
}
