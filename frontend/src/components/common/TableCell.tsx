import { ReactNode } from 'react';
import clsx from 'clsx';

interface TableCellProps {
  children: ReactNode;
  className?: string;
  variant?: 'header' | 'data';
  align?: 'left' | 'center' | 'right';
}

export function TableCell({
  children,
  className,
  variant = 'data',
  align = 'left',
}: TableCellProps) {
  const Component = variant === 'header' ? 'th' : 'td';

  return (
    <Component
      className={clsx(
        'px-2 py-2 sm:px-3 sm:py-3 whitespace-nowrap',
        // Alignment
        align === 'left' && 'text-left',
        align === 'center' && 'text-center',
        align === 'right' && 'text-right',
        // Variant styles
        variant === 'header' && [
          'font-semibold',
          'text-gray-700 dark:text-gray-300',
          'uppercase tracking-wider',
          'text-[10px] sm:text-xs',
        ],
        variant === 'data' && [
          'text-gray-900 dark:text-gray-100',
          'text-xs sm:text-sm',
        ],
        className
      )}
    >
      {children}
    </Component>
  );
}
