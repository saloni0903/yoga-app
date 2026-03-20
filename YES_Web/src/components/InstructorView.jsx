// components/InstructorsView.jsx
import { useInstructors } from '../hooks/useInstructors';

export default function InstructorsView() {
  const { instructors, loading, error } = useInstructors();

  if (loading) return <div className="p-8">Loading instructors...</div>;
  if (error) return <div className="p-8 text-red-500">Error: {error}</div>;

  return (
    <div>
      <div className="mb-6">
        <h3 className="text-3xl font-bold text-gray-800 mb-2">Instructor Management</h3>
        <p className="text-gray-500">Manage and monitor all yoga instructors.</p>
      </div>
      {/* Your table JSX would go here, mapping over the `instructors` array */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        {/* ... table ... */}
      </div>
    </div>
  );
}