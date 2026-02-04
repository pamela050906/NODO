import React from 'react';
import { Search, X } from 'lucide-react';

/**
 * SearchInput con Bootstrap 5
 */
export function SearchInput({ 
  value, 
  onChange, 
  placeholder = 'Buscar...', 
  className = '',
  onClear,
  ...props 
}) {
  const handleClear = () => {
    if (onClear) {
      onClear();
    } else {
      onChange({ target: { value: '' } });
    }
  };

  return (
    <div className={`position-relative ${className}`}>
      <div className="position-absolute top-50 start-0 translate-middle-y ms-3">
        <Search size={20} className="text-muted" />
      </div>
      <input
        type="text"
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        className="form-control ps-5 pe-5"
        {...props}
      />
      {value && (
        <button
          onClick={handleClear}
          className="btn btn-sm position-absolute top-50 end-0 translate-middle-y me-2 p-0 border-0"
          type="button"
          style={{background: 'none'}}
        >
          <X size={18} className="text-muted" />
        </button>
      )}
    </div>
  );
}

export default SearchInput;
