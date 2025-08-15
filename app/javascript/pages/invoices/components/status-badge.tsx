export const StatusBadge = ({ status }: { status: string }) => {
  const statusClasses = {
    paid: 'bg-green-100 text-green-800',
    pending: 'bg-yellow-100 text-yellow-800',
    overdue: 'bg-red-100 text-red-800',
    draft: 'bg-gray-100 text-gray-800'
  };
  
  const className = statusClasses[status as keyof typeof statusClasses] || statusClasses.draft;
  
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${className}`}>
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  );
};