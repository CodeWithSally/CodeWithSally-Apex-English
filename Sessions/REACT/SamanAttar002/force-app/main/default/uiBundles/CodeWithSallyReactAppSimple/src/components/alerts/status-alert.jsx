import { cva } from 'class-variance-authority';
import { AlertCircleIcon, CheckCircle2Icon } from 'lucide-react';
import { Alert, AlertDescription } from '../../components/ui/alert';
import { useId } from 'react';
const statusAlertVariants = cva('', {
  variants: {
    variant: {
      error: '',
      success: '',
    },
  },
  defaultVariants: {
    variant: 'error',
  },
});
/**
 * Status alert component for displaying error or success messages.
 * Returns null if no children are provided.
 */
export function StatusAlert({ children, variant = 'error' }) {
  const descriptionId = useId();
  if (!children) return null;
  const isError = variant === 'error';
  return (
    <Alert
      variant={isError ? 'destructive' : 'default'}
      className={statusAlertVariants({
        variant,
      })}
      aria-describedby={descriptionId}
      role={isError ? 'alert' : 'status'}
    >
      {isError ? (
        <AlertCircleIcon aria-hidden="true" />
      ) : (
        <CheckCircle2Icon aria-hidden="true" />
      )}
      <AlertDescription id={descriptionId}>{children}</AlertDescription>
    </Alert>
  );
}
