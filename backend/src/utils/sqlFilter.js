// src/utils/sqlFilter.js

class SqlFilter {
  constructor() {
    this.where = [];
    this.params = [];
  }

  addRaw(condition) {
    if (condition) this.where.push(condition);
  }

  addEq(column, value) {
    if (value === undefined) return;
    this.params.push(value);
    this.where.push(`${column} = $${this.params.length}`);
  }

  addLike(column, value) {
    if (!value) return;
    this.params.push(value);
    this.where.push(`${column} LIKE $${this.params.length}`);
  }

  addILikeLower(column, lowerLikeValue) {
    // expects value like %abc% already lowercased
    if (!lowerLikeValue) return;
    this.params.push(lowerLikeValue);
    this.where.push(`LOWER(${column}) LIKE $${this.params.length}`);
  }

  addGte(column, value, cast = '') {
    if (!value) return;
    this.params.push(value);
    this.where.push(`${column} >= $${this.params.length}${cast}`);
  }

  addLte(column, value, cast = '') {
    if (!value) return;
    this.params.push(value);
    this.where.push(`${column} <= $${this.params.length}${cast}`);
  }

  build(defaultWhere = 'TRUE') {
    if (this.where.length === 0) {
      return { whereSql: defaultWhere, params: this.params };
    }
    return { whereSql: this.where.join(' AND '), params: this.params };
  }
}

module.exports = { SqlFilter };
