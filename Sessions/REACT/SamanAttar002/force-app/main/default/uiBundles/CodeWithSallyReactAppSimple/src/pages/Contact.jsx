import { useState } from 'react';
import { createLead } from '@/api/leads';

export default function Contact() {
  // One piece of state per field, plus the submit status and any error.
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');
  const [status, setStatus] = useState('idle');
  const [error, setError] = useState('');

  // Send the form to Salesforce (creates a Lead via the Apex REST endpoint).
  async function submit(e) {
    e.preventDefault();
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

  if (status === 'success') {
    return (
      <div className="max-w-md mx-auto p-6">
        <h1 className="text-2xl font-bold mb-2">Contact Us</h1>
        <p className="text-green-700">
          Thanks! We&apos;ve received your message and will be in touch.
        </p>
      </div>
    );
  }

  return (
    <div className="max-w-md mx-auto p-6">
      <h1 className="text-2xl font-bold mb-1">Contact Us</h1>
      <p className="text-gray-600 mb-4">Have a question? Drop us a note.</p>

      <form className="flex flex-col gap-3" onSubmit={submit}>
        <label className="flex flex-col gap-1">
          First Name
          <input
            className="border rounded px-2 py-1"
            required
            value={firstName}
            onChange={e => setFirstName(e.target.value)}
          />
        </label>

        <label className="flex flex-col gap-1">
          Last Name
          <input
            className="border rounded px-2 py-1"
            required
            value={lastName}
            onChange={e => setLastName(e.target.value)}
          />
        </label>

        <label className="flex flex-col gap-1">
          Email
          <input
            type="email"
            className="border rounded px-2 py-1"
            required
            value={email}
            onChange={e => setEmail(e.target.value)}
          />
        </label>

        <label className="flex flex-col gap-1">
          Message
          <textarea
            className="border rounded px-2 py-1"
            rows={4}
            value={message}
            onChange={e => setMessage(e.target.value)}
          />
        </label>

        {status === 'error' && <p className="text-red-600">{error}</p>}

        <button
          type="submit"
          className="bg-blue-600 text-white rounded px-3 py-1 disabled:opacity-50"
          disabled={status === 'submitting'}
        >
          {status === 'submitting' ? 'Sending…' : 'Submit'}
        </button>
      </form>
    </div>
  );
}
