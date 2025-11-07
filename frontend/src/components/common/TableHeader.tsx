import { ReactNode } from 'react';
import clsx from 'clsx';

interface TableHeaderProps {
  children: ReactNode;
  className?: string;
}

export function TableHeader({ children, className }: TableHeaderProps) {
  return (
    <thead
      className={clsx(
        'bg-gray-50 dark:bg-gray-800',
        'border-b-2 border-gray-200 dark:border-gray-700',
        className
      )}
    >
      {children}
    </thead>
  );
}
