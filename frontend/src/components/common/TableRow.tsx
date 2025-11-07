import { ReactNode } from 'react';
import clsx from 'clsx';

interface TableRowProps {
  children: ReactNode;
  className?: string;
  isHeader?: boolean;
}

export function TableRow({ children, className, isHeader = false }: TableRowProps) {
  return (
    <tr
      className={clsx(
        !isHeader && 'hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors',
        className
      )}
    >
      {children}
    </tr>
  );
}
