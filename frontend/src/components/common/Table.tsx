import { ReactNode } from 'react';
import clsx from 'clsx';

interface TableProps {
  children: ReactNode;
  className?: string;
}

export function Table({ children, className }: TableProps) {
  return (
    <div className="w-full overflow-x-auto">
      <table
        className={clsx(
          'w-full border-collapse',
          'text-sm',
          className
        )}
      >
        {children}
      </table>
    </div>
  );
}
