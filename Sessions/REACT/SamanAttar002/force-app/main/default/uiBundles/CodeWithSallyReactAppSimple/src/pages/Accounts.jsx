import { useEffect, useState } from 'react';
import { getAccounts, updateAccount } from '@/api/accounts';
import { decodeHtmlEntities } from '@/lib/utils';

export default function Accounts() {
  // The list of accounts, the row being edited, and any load error.
  const [accounts, setAccounts] = useState([]);
  const [editingId, setEditingId] = useState(null);
  const [draft, setDraft] = useState({
    Name: '',
    Industry: '',
    AnnualRevenue: '',
  });
  const [error, setError] = useState('');

  // Fetch the first 10 accounts once, when the page first renders.
  useEffect(() => {
    getAccounts(10)
      .then(data => setAccounts(data.uiapi.query.Account?.edges ?? []))
      .catch(err => setError(err.message));
  }, []);

  // Copy a row's values into the draft so the inputs can edit them.
  function startEdit(edge) {
    setEditingId(edge?.node?.Id ?? null);
    setDraft({
      Name: decodeHtmlEntities(edge?.node?.Name?.value),
      Industry: decodeHtmlEntities(edge?.node?.Industry?.value),
      AnnualRevenue: edge?.node?.AnnualRevenue?.value?.toString() ?? '',
    });
  }

  // Save the draft back to Salesforce, then patch the row in local state.
  async function handleSave(id) {
    const result = await updateAccount(id, {
      Name: draft.Name,
      Industry: draft.Industry || null,
      AnnualRevenue:
        draft.AnnualRevenue === '' ? null : Number(draft.AnnualRevenue),
    });
    const updated = result.uiapi.AccountUpdate?.Record;
    setAccounts(prev =>
      prev.map(e =>
        e?.node?.Id === id ? { ...e, node: { ...e.node, ...updated } } : e
      )
    );
    setEditingId(null);
  }

  return (
    <div className="max-w-3xl mx-auto p-6">
      <h1 className="text-2xl font-bold mb-1">Accounts</h1>
      <p className="text-gray-600 mb-4">The first 10 accounts in your org.</p>

      {error && <p className="text-red-600 mb-4">{error}</p>}

      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="border-b text-left">
            <th className="py-2">Name</th>
            <th className="py-2">Industry</th>
            <th className="py-2 text-right">Annual Revenue</th>
            <th className="py-2 text-right">Actions</th>
          </tr>
        </thead>
        <tbody>
          {accounts.map(edge => {
            const id = edge?.node?.Id;
            const isEditing = editingId === id;

            return (
              <tr key={id} className="border-b">
                <td className="py-2 pr-2">
                  {isEditing ? (
                    <input
                      className="border rounded px-2 py-1 w-full"
                      value={draft.Name}
                      onChange={e =>
                        setDraft(d => ({ ...d, Name: e.target.value }))
                      }
                    />
                  ) : (
                    decodeHtmlEntities(edge?.node?.Name?.value) || '—'
                  )}
                </td>

                <td className="py-2 pr-2">
                  {isEditing ? (
                    <input
                      className="border rounded px-2 py-1 w-full"
                      value={draft.Industry}
                      onChange={e =>
                        setDraft(d => ({ ...d, Industry: e.target.value }))
                      }
                    />
                  ) : (
                    decodeHtmlEntities(edge?.node?.Industry?.value) || '—'
                  )}
                </td>

                <td className="py-2 pr-2 text-right">
                  {isEditing ? (
                    <input
                      type="number"
                      className="border rounded px-2 py-1 w-full text-right"
                      value={draft.AnnualRevenue}
                      onChange={e =>
                        setDraft(d => ({ ...d, AnnualRevenue: e.target.value }))
                      }
                    />
                  ) : (
                    (edge?.node?.AnnualRevenue?.displayValue ?? '—')
                  )}
                </td>

                <td className="py-2 text-right whitespace-nowrap">
                  {isEditing ? (
                    <>
                      <button
                        className="bg-blue-600 text-white rounded px-3 py-1 mr-2"
                        onClick={() => id && handleSave(id)}
                      >
                        Save
                      </button>
                      <button
                        className="border rounded px-3 py-1"
                        onClick={() => setEditingId(null)}
                      >
                        Cancel
                      </button>
                    </>
                  ) : (
                    <button
                      className="border rounded px-3 py-1"
                      onClick={() => startEdit(edge)}
                    >
                      Edit
                    </button>
                  )}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
