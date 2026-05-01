import ActionButtons from './ActionButtons'
import PropTypes from 'prop-types'

const STATUS_BADGE = {
  accepted: 'bg-green-100 text-green-700',
  pending:  'bg-yellow-100 text-yellow-700',
  rejected: 'bg-gray-100 text-gray-500',
}

export default function RequestCard({ guestEmail, guestName, nutritionistId, onUpdate, rejectionNote, requestedAt, requestId, service, status }) {
  const r = window.I18n?.requests ?? {}
  const statusLabel = r.status?.[status] ?? status

  const date = new Date(requestedAt)
  const locale = window.I18n?.locale === 'pt' ? 'pt-PT' : 'en-GB'
  const dateStr = date.toLocaleDateString(locale, { day: 'numeric', month: 'long', year: 'numeric' })
  const timeStr = date.toLocaleTimeString(locale, { hour: '2-digit', minute: '2-digit' })

  return (
    <div className='bg-white border border-gray-200 rounded-xl p-5 flex flex-col'>

      {/* Avatar + name + service */}
      <div className='flex items-start gap-3 mb-5'>
        <div className='w-14 h-14 rounded-full bg-[#3aaa93] flex items-center justify-center flex-shrink-0'>
          <span className='text-white font-bold text-xl'>{guestName.charAt(0).toUpperCase()}</span>
        </div>
        <div className='min-w-0'>
          <p className='font-semibold text-gray-900 text-base leading-snug'>{guestName}</p>
          <p className='text-sm text-gray-400 mt-0.5'>{service?.name ?? (r.no_service ?? 'No service specified')}</p>
        </div>
      </div>

      {/* Date */}
      <div className='flex items-center gap-2 text-sm text-gray-600 mb-2'>
        <svg width='16' height='16' viewBox='0 0 20 20' fill='none' stroke='#3aaa93' strokeWidth='1.6' strokeLinecap='round' strokeLinejoin='round'>
          <rect x='3' y='4' width='14' height='14' rx='2'/>
          <path d='M3 8h14M7 2v4M13 2v4'/>
        </svg>
        <span>{dateStr}</span>
      </div>

      {/* Time */}
      <div className='flex items-center gap-2 text-sm text-gray-600 mb-5'>
        <svg width='16' height='16' viewBox='0 0 20 20' fill='none' stroke='#3aaa93' strokeWidth='1.6' strokeLinecap='round' strokeLinejoin='round'>
          <circle cx='10' cy='10' r='7'/>
          <path d='M10 6v4l2.5 2.5'/>
        </svg>
        <span>{timeStr}</span>
      </div>

      {/* Action area — pushed to bottom */}
      <div className='mt-auto pt-4 border-t border-gray-100'>
        {status === 'pending' ? (
          <ActionButtons
            nutritionistId={nutritionistId}
            onUpdate={onUpdate}
            requestId={requestId}
            status={status}
          />
        ) : (
          <div className='flex flex-col gap-1.5'>
            <span className={`${STATUS_BADGE[status]} font-medium px-2.5 py-1 rounded-full text-xs self-start`}>
              {statusLabel}
            </span>
            {status === 'rejected' && rejectionNote && (
              <p className='text-xs text-gray-400 italic'>{rejectionNote}</p>
            )}
          </div>
        )}
      </div>

    </div>
  )
}

RequestCard.propTypes = {
  guestEmail:     PropTypes.string.isRequired,
  guestName:      PropTypes.string.isRequired,
  nutritionistId: PropTypes.number.isRequired,
  onUpdate:       PropTypes.func.isRequired,
  rejectionNote:  PropTypes.string,
  requestedAt:    PropTypes.string.isRequired,
  requestId:      PropTypes.number.isRequired,
  service:        PropTypes.shape({ location: PropTypes.string.isRequired, name: PropTypes.string.isRequired }),
  status:         PropTypes.string.isRequired,
}
