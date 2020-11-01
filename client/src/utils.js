function appendLeadingZeroes(n){
    if(n <= 9){
      return "0" + n;
    }
    return n
  }

function convertDate(passedDate) {
    const date = new Date(passedDate)
    let formatted_date = '' + date.getFullYear() + appendLeadingZeroes((date.getMonth() + 1)) + appendLeadingZeroes(date.getDate())
    return formatted_date
}

function sqlToJsDate(date) {
    let dateSplit = date.split('T');
    return new Date(date.replace(' ', 'T'));    ;
}

function stringToJsDate(dateString) {
  var year = dateString.substring(0,4);
  var month = dateString.substring(4,6);
  var day = dateString.substring(6,8);
  return new Date(year, month-1, day);
}

function isValidStringDate(dateString) {
  var year = dateString.substring(0,4);
  var month = dateString.substring(4,6);
  var day = dateString.substring(6,8);
  if (month > 12 || month < 1) {
      return false;
  }
  if (day > 31 || day < 1) {
    return false;
  }
  return true;
}
function differenceInTwoDates(s_date, e_date){
  const date1 = stringToJsDate(s_date);
  const date2 = stringToJsDate(e_date);
  const diffTime = Math.abs(date2 - date1);
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)); 
  return diffDays;

}

export {convertDate, sqlToJsDate, stringToJsDate, differenceInTwoDates, isValidStringDate }