import { ReactNode } from 'react';
import clsx from 'clsx';

interface TableBodyProps {
  children: ReactNode;
  className?: string;
}

export function TableBody({ children, className }: TableBodyProps) {
  return (
    <tbody
      className={clsx(
        'bg-white dark:bg-gray-900',
        'divide-y divide-gray-200 dark:divide-gray-700',
        className
      )}
    >
      {children}
    </tbody>
  );
}
