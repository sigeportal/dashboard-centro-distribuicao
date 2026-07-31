export function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0);
}

export function formatPercentage(val) {
  return new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(val || 0) + '%';
}


export function formatDate(dateString) {
  if (!dateString || dateString === '-' || dateString === '1899-12-30' || dateString === 'Recentemente' || dateString === 'Atualizado') return '-';
  try {
    const str = String(dateString).trim();
    const match = str.match(/^(\d{4})-(\d{2})-(\d{2})/);
    if (match) {
      const [, yyyy, mm, dd] = match;
      return `${dd}/${mm}/${yyyy}`;
    }
    const d = new Date(str);
    if (!isNaN(d.getTime())) {
      return d.toLocaleDateString('pt-BR', {
        timeZone: 'America/Campo_Grande'
      });
    }
    return str;
  } catch (err) {
    return dateString;
  }
}

export function formatDatehora(dateString) {
  if (!dateString || dateString === '-' || dateString === '1899-12-30' || dateString === 'Recentemente' || dateString === 'Atualizado') return '-';
  try {
    const str = String(dateString).trim();
    const match = str.match(/^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})/);
    if (match) {
      const [, yyyy, mm, dd, hh, min, ss] = match;
      if (hh !== '00' || min !== '00' || ss !== '00') {
        return `${dd}/${mm}/${yyyy} ${hh}:${min}:${ss}`;
      }
      return `${dd}/${mm}/${yyyy}`;
    }
    const d = new Date(str);
    if (!isNaN(d.getTime())) {
      return d.toLocaleString('pt-BR', {
        timeZone: 'America/Campo_Grande',
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      });
    }
    return formatDate(str);
  } catch (err) {
    return dateString;
  }
}

export function formatExcelDate(serial) {
  if (serial === null || serial === undefined || isNaN(Number(serial))) return '-';
  const num = Number(serial);
  const msPerDay = 86400000;
  const baseDateMs = Date.UTC(1899, 11, 30);
  const date = new Date(baseDateMs + num * msPerDay);
  
  const dd = String(date.getUTCDate()).padStart(2, '0');
  const mm = String(date.getUTCMonth() + 1).padStart(2, '0');
  const yyyy = date.getUTCFullYear();
  
  return `${dd}/${mm}/${yyyy}`;
}

export function formatExcelTime(fraction) {
  if (fraction === null || fraction === undefined || isNaN(Number(fraction))) return '-';
  const num = Number(fraction);
  // Extract time from the fraction (portion of a 24h day)
  const dayFraction = num % 1;
  const totalSeconds = Math.round(dayFraction * 86400);
  
  const hours = Math.floor(totalSeconds / 3600) % 24;
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  
  const hh = String(hours).padStart(2, '0');
  const mm = String(minutes).padStart(2, '0');
  const ss = String(seconds).padStart(2, '0');
  
  return `${hh}:${mm}:${ss}`;
}

// ---------- Mascaramento LGPD ----------
export function maskCpfCnpj(doc) {
  if (!doc || doc === '-') return doc;
  const digits = doc.replace(/\D/g, '');
  if (digits.length === 11) {
    return `***.${digits.slice(3, 6)}.${digits.slice(6, 9)}-**`;
  }
  if (digits.length === 14) {
    return `**.${digits.slice(2, 5)}.${digits.slice(5, 8)}/****-**`;
  }
  if (doc.length <= 4) return '*'.repeat(doc.length);
  return doc[0] + '*'.repeat(doc.length - 2) + doc[doc.length - 1];
}

export function maskPhone(phone) {
  if (!phone || phone === '-') return phone;
  return phone.replace(/\d(?=\d{4})/g, '*');
}

export function maskEmail(email) {
  if (!email || email === '-') return email;
  const atIdx = email.indexOf('@');
  if (atIdx <= 0) return email;
  const local = email.slice(0, atIdx);
  const domain = email.slice(atIdx);
  if (local.length <= 2) return local[0] + '*' + domain;
  return local[0] + '*'.repeat(local.length - 2) + local[local.length - 1] + domain;
}
