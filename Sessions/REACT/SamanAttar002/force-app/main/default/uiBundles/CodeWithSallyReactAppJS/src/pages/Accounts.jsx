import { useEffect, useState } from 'react';
import { getAccounts, updateAccount } from '@/api/accounts';
import {
  Button,
  Input,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui';
import { Badge } from '@/components/ui/badge';
import { StatusAlert } from '@/components/alerts/status-alert';
import { decodeHtmlEntities } from '@/lib/utils';

export default function Accounts() {
  const [accounts, setAccounts] = useState([]);
  const [editingId, setEditingId] = useState(null);
  const [draft, setDraft] = useState({
    Name: '',
    Industry: '',
    AnnualRevenue: '',
  });
  const [error, setError] = useState('');
  useEffect(() => {
    getAccounts(10)
      .then(data => setAccounts(data.uiapi.query.Account?.edges ?? []))
      .catch(err => setError(err.message));
  }, []);
  function startEdit(edge) {
    setEditingId(edge?.node?.Id ?? null);
    setDraft({
      // Decode HTML entities so the input shows "Tom & Jerry", not "Tom &amp; Jerry".
      Name: decodeHtmlEntities(edge?.node?.Name?.value),
      Industry: decodeHtmlEntities(edge?.node?.Industry?.value),
      // AnnualRevenue.value is the raw number; displayValue is the formatted "$1,000".
      AnnualRevenue: edge?.node?.AnnualRevenue?.value?.toString() ?? '',
    });
  }
  async function handleSave(id) {
    const result = await updateAccount(id, {
      Name: draft.Name,
      Industry: draft.Industry || null,
      AnnualRevenue:
        draft.AnnualRevenue === '' ? null : Number(draft.AnnualRevenue),
    });

    // Patch the row in local state so the table reflects the change without a refetch.
    const updated = result.uiapi.AccountUpdate?.Record;
    setAccounts(prev =>
      prev.map(e =>
        e?.node?.Id === id
          ? {
              ...e,
              node: {
                ...e.node,
                ...updated,
              },
            }
          : e
      )
    );
    setEditingId(null);
  }
  return (
    <div className="max-w-4xl mx-auto px-4 py-12">
      <h1 className="text-4xl font-bold text-gray-900 mb-2 text-center">
        Accounts
      </h1>
      <p className="text-gray-600 text-center mb-8">
        The first 10 accounts in your org.
      </p>

      {error && (
        <div className="mb-6">
          <StatusAlert>{error}</StatusAlert>
        </div>
      )}

      <div className="overflow-hidden rounded-xl ring-1 ring-foreground/10">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Industry</TableHead>
              <TableHead className="text-right">Annual Revenue</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {accounts.map(edge => {
              const id = edge?.node?.Id;
              const isEditing = editingId === id;
              return (
                <TableRow key={id}>
                  <TableCell className="font-medium">
                    {isEditing ? (
                      <Input
                        value={draft.Name}
                        onChange={e =>
                          setDraft(d => ({
                            ...d,
                            Name: e.target.value,
                          }))
                        }
                        placeholder="Name"
                      />
                    ) : (
                      decodeHtmlEntities(edge?.node?.Name?.value) || '—'
                    )}
                  </TableCell>

                  <TableCell>
                    {isEditing ? (
                      <Input
                        value={draft.Industry}
                        onChange={e =>
                          setDraft(d => ({
                            ...d,
                            Industry: e.target.value,
                          }))
                        }
                        placeholder="Industry"
                      />
                    ) : edge?.node?.Industry?.value ? (
                      <Badge variant="secondary">
                        {decodeHtmlEntities(edge.node.Industry.value)}
                      </Badge>
                    ) : (
                      <span className="text-gray-400">—</span>
                    )}
                  </TableCell>

                  <TableCell className="text-right tabular-nums">
                    {isEditing ? (
                      <Input
                        type="number"
                        className="text-right"
                        value={draft.AnnualRevenue}
                        onChange={e =>
                          setDraft(d => ({
                            ...d,
                            AnnualRevenue: e.target.value,
                          }))
                        }
                        placeholder="0"
                      />
                    ) : (
                      (edge?.node?.AnnualRevenue?.displayValue ?? '—')
                    )}
                  </TableCell>

                  <TableCell className="text-right">
                    {isEditing ? (
                      <div className="flex justify-end gap-2">
                        <Button size="sm" onClick={() => id && handleSave(id)}>
                          Save
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => setEditingId(null)}
                        >
                          Cancel
                        </Button>
                      </div>
                    ) : (
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => startEdit(edge)}
                      >
                        Edit
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
